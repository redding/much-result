# frozen_string_literal: true

require "assert"
require "much-result/transaction"

class MuchResult::Transaction
  class UnitTests < Assert::Context
    desc "MuchResult::Transaction"
    subject{ unit_class }

    let(:unit_class){ MuchResult::Transaction }

    let(:receiver1){ Factory.transaction_receiver }
    let(:value1){ Factory.value }
    let(:kargs1) do
      { value: value1 }
    end
    let(:block1) do
      ->(transaction){ transaction.set(block_called: true) }
    end

    should have_imeths :halt_throw_value, :call

    should "know its halt throw value" do
      assert_that(subject.halt_throw_value).equals(:muchresult_transaction_halt)
    end

    should "call transactions on a transaction receiver" do
      MuchStub.tap_on_call(unit_class, :new) do |transaction, new_call|
        @new_call = new_call
        MuchStub.on_call(transaction, :call) do |transaction_call|
          @transaction_call = transaction_call
        end
      end

      subject.call(receiver1, **kargs1, &block1)

      assert_that(@new_call.pargs).equals([receiver1])
      assert_that(@new_call.kargs).equals(kargs1)
      assert_that(@transaction_call.block).equals(block1)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject{ unit_class.new(receiver1, **kargs1) }

    should have_imeths :result, :call, :rollback, :halt

    should "complain if given a nil receiver" do
      assert_that(->{
        unit_class.new(nil, **kargs1)
      }).raises(ArgumentError)
    end

    should "know its result" do
      assert_that(subject.result).is_instance_of(MuchResult)
      assert_that(subject.result.value).equals(value1)
      assert_that(subject.result.much_result_transaction_rolled_back).is_false
      assert_that(subject.result.much_result_transaction_halted).is_false
    end

    should "delegate result methods to its result" do
      assert_that(subject.value).equals(subject.result.value)
      assert_that(subject.success?).equals(subject.result.success?)
      assert_that(subject.results).equals(subject.result.results)
    end

    should "call transactions on the transaction receiver" do
      MuchStub.tap_on_call(block1, :call) do |_, call|
        @block_call = call
      end

      result = subject.call(&block1)

      assert_that(result).equals(subject.result)
      assert_that(subject.block_called).is_true
      assert_that(@block_call.args).equals([subject])
      assert_that(receiver1.last_transaction_call.block).is_not_nil
    end

    should "rollback transactions on the transaction receiver" do
      assert_that(->{ subject.rollback }).raises(MuchResult::Rollback)

      block1 = ->(transaction){ transaction.rollback }
      assert_that(->{ subject.call(&block1) }).does_not_raise
      assert_that(receiver1.rolled_back?).is_true

      block1 = ->(_transaction){ raise StandardError }
      assert_that(->{ subject.call(&block1) }).raises(StandardError)
      assert_that(receiver1.rolled_back?).is_true

      assert_that(subject.result.much_result_transaction_rolled_back).is_true
      assert_that(subject.result.much_result_transaction_halted).is_false
    end

    should "halt transactions" do
      catch(unit_class.halt_throw_value) do
        subject.capture{ "something1" }
        subject.halt
        subject.capture{ "something2" }
      end

      assert_that(subject.sub_results.size).equals(1)

      assert_that(subject.result.much_result_transaction_rolled_back).is_false
      assert_that(subject.result.much_result_transaction_halted).is_true
    end
  end
end
