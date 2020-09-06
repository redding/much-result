require "much-result/version"
require "much-result/aggregate"
require "much-result/transaction"

class MuchResult
  SUCCESS = "success".freeze
  FAILURE = "failure".freeze

  Error    = Class.new(StandardError)
  Rollback = Class.new(RuntimeError)

  def self.success(backtrace: caller, **kargs)
    new(MuchResult::SUCCESS, **kargs, backtrace: backtrace)
  end

  def self.failure(backtrace: caller, **kargs)
    new(MuchResult::FAILURE, **kargs, backtrace: backtrace)
  end

  def self.for(value, backtrace: caller, **kargs)
    if value.respond_to?(:to_much_result)
      return value.to_much_result(**kargs, backtrace: backtrace)
    end

    new(
      !!value ? MuchResult::SUCCESS : MuchResult::FAILURE,
      **kargs,
      backtrace: backtrace
    )
  end

  def self.tap(backtrace: caller, **kargs)
    success(backtrace: backtrace, **kargs).tap { |result|
      yield result if block_given?
    }
  end

  def self.transaction(receiver, backtrace: caller, **kargs, &block)
    MuchResult::Transaction.call(receiver, backtrace: backtrace, **kargs, &block)
  end

  attr_reader :sub_results, :description, :backtrace

  def initialize(result_value, description: nil, backtrace: caller, **kargs)
    @result_value = result_value
    @description  = description
    @backtrace    = backtrace

    set(**kargs)

    @sub_results = []
    reset_sub_results_cache
  end

  def set(**kargs)
    @data = ::OpenStruct.new((@data || {}).to_h.merge(**kargs))
    self
  end

  def success?
    if @success_predicate.nil?
      @success_predicate =
        @sub_results.reduce(@result_value == MuchResult::SUCCESS) { |acc, result|
          acc && result.success?
        }
    end

    @success_predicate
  end

  def failure?
    !success?
  end

  def capture(backtrace: caller, **kargs)
    self.class.for(
      (yield if block_given?),
      backtrace: backtrace,
      **kargs
    ).tap { |result| add_sub_result(result) }
  end

  def capture!(backtrace: caller, **kargs, &block)
    capture(backtrace: caller, **kargs, &block).tap { |result|
      raise(result.capture_exception) if result.failure?
    }
  end

  # Prefer any `#exception` set on the data. Fallback to building an exception
  # from the description/backtrace of the result.
  def capture_exception
    @data.exception || build_default_capture_exception
  end

  def success_sub_results
    @success_sub_results ||= @sub_results.select { |result| result.success? }
  end

  def failure_sub_results
    @failure_sub_results ||= @sub_results.select { |result| result.failure? }
  end

  def all_results
    @all_results ||=
      [self] +
      @sub_results.flat_map { |result| result.all_results }
  end

  def all_success_results
    @all_success_results ||=
      [*(self if success?)] +
      @sub_results.flat_map { |result| result.all_success_results }
  end

  def all_failure_results
    @all_failure_results ||=
      [*(self if failure?)] +
      @sub_results.flat_map { |result| result.all_failure_results }
  end

  def get_for_sub_results(attribute_name)
    MuchResult::Aggregate.(sub_results.map(&attribute_name.to_sym))
  end

  def get_for_success_sub_results(attribute_name)
    MuchResult::Aggregate.(success_sub_results.map(&attribute_name.to_sym))
  end

  def get_for_failure_sub_results(attribute_name)
    MuchResult::Aggregate.(failure_sub_results.map(&attribute_name.to_sym))
  end

  def get_for_all_results(attribute_name)
    MuchResult::Aggregate.(all_results.map(&attribute_name.to_sym))
  end

  def get_for_all_success_results(attribute_name)
    MuchResult::Aggregate.(all_success_results.map(&attribute_name.to_sym))
  end

  def get_for_all_failure_results(attribute_name)
    MuchResult::Aggregate.(all_failure_results.map(&attribute_name.to_sym))
  end

  def to_much_result(backtrace: caller, **kargs)
    self.set(**kargs)
  end

  def inspect
    "#<#{self.class}:#{"0x0%x" % (object_id << 1)} "\
      "#{success? ? "SUCCESS" : "FAILURE"} "\
      "#{"@description=#{@description.inspect} " if @description}"\
      "@sub_results=#{@sub_results.inspect}>"
  end

  private

  def add_sub_result(result)
    @sub_results.push(result).tap { reset_sub_results_cache }
  end

  def build_default_capture_exception
    Error.new(description).tap { |exception| exception.set_backtrace(backtrace) }
  end

  def reset_sub_results_cache
    @success_predicate = nil
    @success_sub_results = nil
    @failure_sub_results = nil
    @all_results = nil
    @all_success_results = nil
    @all_failure_results = nil
  end

  def respond_to_missing?(*args)
    @data.send(:respond_to_missing?, *args)
  end

  def method_missing(method, *args, &block)
    @data.public_send(method, *args, &block)
  end
end
