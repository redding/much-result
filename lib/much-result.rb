require "much-result/version"
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
    return value.set(**kargs) if value.kind_of?(MuchResult)

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

  attr_reader :description, :backtrace

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
      raise(result_exception) if result.failure?
    }
  end

  def result_exception
    @result_exception ||=
      Error.new(description).tap { |exception|
        exception.set_backtrace(backtrace)
      }
  end

  def results
    @results ||=
      [self] +
      @sub_results.flat_map { |result| result.results }
  end

  def success_results
    @success_results ||=
      [*(self if success?)] +
      @sub_results.flat_map { |result| result.success_results }
  end

  def failure_results
    @failure_results ||=
      [*(self if failure?)] +
      @sub_results.flat_map { |result| result.failure_results }
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

  def reset_sub_results_cache
    @success_predicate = nil
    @results = nil
    @success_results = nil
    @failure_results = nil
  end

  def respond_to_missing?(*args)
    @data.send(:respond_to_missing?, *args)
  end

  def method_missing(method, *args, &block)
    @data.public_send(method, *args, &block)
  end
end
