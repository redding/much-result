require "much-result"

class MuchResult; end
class MuchResult::Item < ::OpenStruct
  def self.success(backtrace: caller, **kargs)
    new(**kargs, result: MuchResult::SUCCESS, backtrace: backtrace)
  end

  def self.failure(backtrace: caller, **kargs)
    new(**kargs, result: MuchResult::FAILURE, backtrace: backtrace)
  end

  def self.for_boolean(value, backtrace: caller, **kargs)
    new(
      **kargs,
      result: value ? MuchResult::SUCCESS : MuchResult::FAILURE,
      backtrace: backtrace
    )
  end

  def initialize(result: MuchResult::SUCCESS, backtrace: caller, **kargs)
    super(**kargs, result: result, backtrace: backtrace)
  end

  def success?
    result == MuchResult::SUCCESS
  end

  def failure?
    result == MuchResult::FAILURE
  end

  def identifier
    super # Optional
  end

  def description
    super # Optional
  end

  def backtrace
    super
  end

  def result_exception
    @result_exception ||=
      MuchResult::Error.new(description).tap { |exception|
        exception.set_backtrace(backtrace)
      }
  end

  # For API compatibility with MuchResult
  def items
    @items ||= [self]
  end

  # For API compatibility with MuchResult
  def success_items
    @success_items ||= success? ? items : []
  end

  # For API compatibility with MuchResult
  def failure_items
    @failure_items ||= failure? ? items : []
  end
end
