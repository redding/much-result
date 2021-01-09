# frozen_string_literal: true

require "assert/factory"
require "much-stub/call"

module Factory
  extend Assert::Factory

  def self.value
    [Factory.integer, Factory.string, Object.new].sample
  end

  def self.hash_value(with_nested_hash = true)
    {
      value1: Factory.value,
      value2: with_nested_hash ? Factory.hash_value(false) : Factory.value,
    }
  end

  def self.backtrace
    Factory.integer(3).times.map{ Factory.path }
  end

  def self.transaction_receiver
    FakeTransactionReceiver.new
  end

  class FakeTransactionReceiver
    attr_reader :last_transaction_call

    def transaction(&block)
      @rolled_back = false
      @last_transaction_call = MuchStub::Call.new(&block)
      block.call
    rescue => ex
      @rolled_back = true
      raise ex
    end

    def rolled_back?
      !!@rolled_back
    end
  end
end
