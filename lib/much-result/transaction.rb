# frozen_string_literal: true

require "much-result"

class MuchResult; end

class MuchResult::Transaction
  def self.halt_throw_value
    :muchresult_transaction_halt
  end

  def self.call(receiver, **result_kargs, &block)
    new(receiver, **result_kargs).call(&block)
  end

  def initialize(receiver, **result_kargs)
    raise(ArgumentError, "`receiver` can't be nil.") if receiver.nil?

    @receiver = receiver
    @result_kargs = result_kargs

    result.much_result_transaction_rolled_back = false
    result.much_result_transaction_halted = false
  end

  def result
    @result ||= MuchResult.success(**@result_kargs)
  end

  def call(&block)
    begin
      @receiver.transaction do
        catch(self.class.halt_throw_value){ block.call(self) }
      end
    rescue MuchResult::Rollback
      # do nothing
    end

    result
  end

  def rollback
    result.much_result_transaction_rolled_back = true
    raise MuchResult::Rollback
  end

  def halt
    result.much_result_transaction_halted = true
    throw(self.class.halt_throw_value)
  end

  private

  def respond_to_missing?(*args)
    result.send(:respond_to_missing?, *args)
  end

  def method_missing(method, *args, &block)
    result.public_send(method, *args, &block)
  end
end
