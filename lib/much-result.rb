require "much-result/version"
require "much-result/item"

class MuchResult
  SUCCESS = "success".freeze
  FAILURE = "failure".freeze

  Error = Class.new(StandardError)

  def self.success(backtrace: caller, **kargs)
    new(backtrace: backtrace, **kargs).tap { |result|
      result.add_item(MuchResult::Item.success(backtrace: backtrace, **kargs))
    }
  end

  def self.failure(backtrace: caller, **kargs)
    new(backtrace: backtrace, **kargs).tap { |result|
      result.add_item(MuchResult::Item.failure(backtrace: backtrace, **kargs))
    }
  end

  def self.for(value, backtrace: caller, **kargs)
    return value.set(**kargs) if value.kind_of?(MuchResult)

    new(backtrace: backtrace, **kargs).tap { |result|
      result.add_item(
        MuchResult::Item.for(value, backtrace: backtrace, **kargs)
      )
    }
  end

  attr_reader :description, :backtrace

  def initialize(description: nil, backtrace: caller, **kargs)
    @description = description
    @backtrace = backtrace
    @result_items = []

    set(**kargs)
  end

  def success?
    if @success_predicate.nil?
      @success_predicate =
        @result_items.reduce(true) { |acc, item| acc && item.success? }
    end

    @success_predicate
  end

  def failure?
    !success?
  end

  def set(**kargs)
    @data = ::OpenStruct.new((@data || {}).to_h.merge(**kargs))
    self
  end

  def add_item(item)
    @result_items.push(item)
  end

  def result_exception
    @result_exception ||=
      Error.new(description).tap { |exception|
        exception.set_backtrace(backtrace)
      }
  end

  def items
    @items ||= @result_items.flat_map { |item| item.items }
  end

  def success_items
    @success_items || @result_items.flat_map { |item| item.success_items }
  end

  def failure_items
    @failure_items || @result_items.flat_map { |item| item.failure_items }
  end

  private

  def respond_to_missing?(*args)
    @data.send(:respond_to_missing?, *args)
  end

  def method_missing(method, *args, &block)
    @data.public_send(method, *args, &block)
  end
end
