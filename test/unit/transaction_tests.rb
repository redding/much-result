require "assert"
require "much-result/transaction"

class MuchResult::Transaction
  class UnitTests < Assert::Context
    desc "MuchResult::Transaction"
    subject { unit_class }

    let(:unit_class) { MuchResult::Transaction }

    let(:receiver1) { Factory.transaction_receiver }
    let(:value1) { Factory.value }
    let(:kargs1) {
      { value:  value1 }
    }
    let(:block1) {
      ->(transaction) { transaction.set(block_called: true) }
    }

    should have_imeths :call

    should "call transactions on a transaction receiver" do
      MuchStub.tap_on_call(unit_class, :new) { |transaction, new_call|
        @new_call = new_call
        MuchStub.on_call(transaction, :call) { |transaction_call|
          @transaction_call = transaction_call
        }
      }

      subject.call(receiver1, **kargs1, &block1)

      assert_that(@new_call.pargs).equals([receiver1])
      assert_that(@new_call.kargs).equals(kargs1)
      assert_that(@transaction_call.block).equals(block1)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { transaction1 }

    let(:transaction1) { unit_class.new(receiver1, **kargs1) }

    should have_imeths :result, :call, :rollback

    should "know its result" do
      assert_that(subject.result).is_instance_of(MuchResult)
      assert_that(subject.result.value).equals(value1)
    end

    should "delegate result methods to its result" do
      assert_that(subject.value).equals(subject.result.value)
      assert_that(subject.success?).equals(subject.result.success?)
      assert_that(subject.results).equals(subject.result.results)
    end

    should "call transactions on the transaction receiver" do
      MuchStub.tap_on_call(block1, :call) { |_, call|
        @block_call = call
      }

      result = subject.call(&block1)

      assert_that(result).equals(subject.result)
      assert_that(subject.block_called).is_true
      assert_that(@block_call.args).equals([subject])
      assert_that(receiver1.last_transaction_call.block).is_not_nil
    end

    should "rollback transactions on the transaction receiver" do
      assert_that(-> { subject.rollback }).raises(MuchResult::Rollback)

      block1 = ->(transaction) { transaction.rollback }
      assert_that(-> {subject.call(&block1)}).does_not_raise
      assert_that(receiver1.rolled_back?).is_true

      block1 = ->(transaction) { raise StandardError }
      assert_that(-> {subject.call(&block1)}).raises(StandardError)
      assert_that(receiver1.rolled_back?).is_true
    end
  end
end
