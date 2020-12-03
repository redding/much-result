require "assert"
require "much-result"

class MuchResult
  class UnitTests < Assert::Context
    desc "MuchResult"
    subject { unit_class }

    let(:unit_class) { MuchResult }

    let(:identifier1) { Factory.string }
    let(:description1) { Factory.string }
    let(:backtrace1) { Factory.backtrace }
    let(:value1) { Factory.value }

    should have_imeths :success, :failure, :for, :tap, :transaction
    should have_accessors :default_transaction_receiver

    should "build success instances" do
      result = subject.success

      assert_that(result.success?).is_true
      assert_that(result.failure?).is_false

      assert_that(result.sub_results).equals([])
      assert_that(result.success_sub_results).equals([])
      assert_that(result.failure_sub_results).equals([])

      assert_that(result.all_results).equals([result])
      assert_that(result.all_success_results).equals([result])
      assert_that(result.all_failure_results).equals([])
    end

    should "build failure instances" do
      result = subject.failure

      assert_that(result.success?).is_false
      assert_that(result.failure?).is_true

      assert_that(result.sub_results).equals([])
      assert_that(result.success_sub_results).equals([])
      assert_that(result.failure_sub_results).equals([])

      assert_that(result.all_results).equals([result])
      assert_that(result.all_success_results).equals([])
      assert_that(result.all_failure_results).equals([result])
    end

    should "build instances based on given values" do
      true_result = subject.for(true, value: value1)
      assert_that(true_result.success?).is_true
      assert_that(true_result.failure?).is_false
      assert_that(true_result.value).equals(value1)

      false_result = subject.for(false, value: value1)
      assert_that(false_result.success?).is_false
      assert_that(false_result.failure?).is_true
      assert_that(false_result.value).equals(value1)

      value1_result = subject.for(value1, value: value1)
      assert_that(value1_result.success?).is_true
      assert_that(value1_result.failure?).is_false
      assert_that(value1_result.value).equals(value1)

      nil_result = subject.for(nil, value: value1)
      assert_that(nil_result.success?).is_false
      assert_that(nil_result.failure?).is_true
      assert_that(nil_result.value).equals(value1)

      result_result = subject.for(true_result, value2: value1)
      assert_that(result_result).is_the_same_as(true_result)
      assert_that(result_result.value2).equals(value1)
    end

    should "build instances yielded to a given block" do
      yielded_result = nil
      tap_result =
        subject.tap { |result|
          yielded_result = result

          assert_that(result.success?).is_true
          assert_that(result.sub_results.size).equals(0)
          assert_that(result.all_results.size).equals(1)
        }
      assert_that(tap_result).is_the_same_as(yielded_result)
    end

    should "call transactions on a transaction receiver" do
      MuchStub.on_call(MuchResult::Transaction, :call) { |call|
        @transaction_call = call
      }

      receiver1 = Factory.transaction_receiver
      kargs1 = {
        backtrace: Factory.backtrace,
        value: value1
      }
      block1 = -> {}
      subject.transaction(receiver1, **kargs1, &block1)

      assert_that(@transaction_call.pargs).equals([receiver1])
      assert_that(@transaction_call.kargs).equals(kargs1)
      assert_that(@transaction_call.block).equals(block1)
    end

    should "halt transactions" do
      receiver1 = Factory.transaction_receiver
      result =
        subject.transaction(receiver1) do |transaction|
          transaction.capture { "something1"}
          transaction.halt
          transaction.capture { "something2" }
        end

      assert_that(result.sub_results.size).equals(1)
    end

    should "configure default transaction receivers" do
      MuchStub.on_call(MuchResult::Transaction, :call) { |call|
        @transaction_call = call
      }

      receiver1 = Factory.transaction_receiver
      kargs1 = {
        backtrace: Factory.backtrace,
        value: value1
      }
      block1 = -> {}

      assert_that(subject.default_transaction_receiver).is_nil
      assert_that(-> {
        subject.transaction(**kargs1, &block1)
      }).raises(ArgumentError)

      subject.default_transaction_receiver = receiver1
      subject.transaction(**kargs1, &block1)

      assert_that(subject.default_transaction_receiver).equals(receiver1)
      assert_that(@transaction_call.pargs).equals([receiver1])
      assert_that(@transaction_call.kargs).equals(kargs1)
      assert_that(@transaction_call.block).equals(block1)

      subject.default_transaction_receiver = nil
      assert_that(subject.default_transaction_receiver).is_nil
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.success }

    let(:failure1) {
      unit_class.failure(description: Factory.string)
    }
    let(:failure2) {
      unit_class.failure(exception: StandardError.new(Factory.string))
    }

    should have_imeths :description, :backtrace, :set
    should have_imeths :attributes, :attribute_names
    should have_imeths :success?, :failure?
    should have_imeths :capture_for, :capture_for!
    should have_imeths :capture_for_all, :capture_for_all!
    should have_imeths :capture, :capture!
    should have_imeths :capture_all, :capture_all!
    should have_imeths :capture_exception
    should have_imeths :sub_results, :success_sub_results, :failure_sub_results
    should have_imeths :all_results, :all_success_results, :all_failure_results
    should have_imeths :get_for_sub_results
    should have_imeths :get_for_success_sub_results, :get_for_failure_sub_results
    should have_imeths :get_for_all_results
    should have_imeths :get_for_all_success_results, :get_for_all_failure_results
    should have_imeths :to_much_result

    should "know its attributes" do
      assert_that(subject.description).is_nil
      assert_that(subject.backtrace).is_not_nil
      assert_that(subject.backtrace).is_not_empty

      result =
        unit_class.success(
          identifier: identifier1,
          description: description1,
          backtrace: backtrace1,
          value: value1
        )
      assert_that(result.identifier).equals(identifier1)
      assert_that(result.description).equals(description1)
      assert_that(result.backtrace).equals(backtrace1)
      assert_that(result.value).equals(value1)

      exception = result.capture_exception
      assert_that(exception).is_instance_of(MuchResult::Error)
      assert_that(exception.message).equals(description1)
      assert_that(exception.backtrace).equals(backtrace1)
    end

    should "allow setting arbitrary attributes" do
      assert_that(subject.other_value).is_nil

      subject.set(other_value: value1)
      assert_that(subject.other_value).equals(value1)
    end

    should "provide details on dynamically defined attributes" do
      assert_that(subject.attributes).is_empty

      subject.new_attribute = "new_value"

      assert_that(subject.attributes).equals(new_attribute: "new_value")
      assert_that(subject.attribute_names).equals([:new_attribute])
    end

    should "capture MuchResults as sub-results" do
      subject.capture_for(unit_class.success(values: { value1: Factory.value }))
      assert_that(subject.success?).is_true
      assert_that(subject.sub_results.size).equals(1)
      assert_that(subject.success_sub_results.size).equals(1)
      assert_that(subject.failure_sub_results.size).equals(0)
      assert_that(subject.get_for_sub_results("values")[:value1]).equals(
        [
          subject.success_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_success_sub_results("values")[:value1]).equals(
        [
          subject.success_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_failure_sub_results("values")).equals(
        [])
      assert_that(subject.all_results.size).equals(2)
      assert_that(subject.all_success_results.size).equals(2)
      assert_that(subject.all_failure_results.size).equals(0)
      assert_that(subject.get_for_all_results("values")[:value1]).equals(
        [
          nil,
          subject.success_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_all_success_results("values")[:value1]).equals(
        [
          nil,
          subject.success_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_all_failure_results("values")).equals(
        [])

      subject.capture_for(unit_class.failure(values: { value1: Factory.value }))
      assert_that(subject.success?).is_false
      assert_that(subject.sub_results.size).equals(2)
      assert_that(subject.success_sub_results.size).equals(1)
      assert_that(subject.failure_sub_results.size).equals(1)
      assert_that(subject.get_for_sub_results("values")[:value1]).equals(
        [
          subject.success_sub_results.first.values[:value1],
          subject.failure_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_success_sub_results("values")[:value1]).equals(
        [
          subject.success_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_failure_sub_results("values")[:value1]).equals(
        [
          subject.failure_sub_results.first.values[:value1]
        ])
      assert_that(subject.all_results.size).equals(3)
      assert_that(subject.all_success_results.size).equals(1)
      assert_that(subject.all_failure_results.size).equals(2)
      assert_that(subject.get_for_all_results("values")[:value1]).equals(
        [
          nil,
          subject.success_sub_results.first.values[:value1],
          subject.failure_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_all_success_results("values")[:value1]).equals(
        [
          subject.success_sub_results.first.values[:value1]
        ])
      assert_that(subject.get_for_all_failure_results("values")[:value1]).equals(
        [
          nil,
          subject.failure_sub_results.first.values[:value1]
        ])

      result = unit_class.success

      result.capture_for([true, Factory.integer, Factory.string].sample)
      assert_that(result.success?).is_true
      assert_that(result.sub_results.size).equals(1)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(0)
      assert_that(result.all_results.size).equals(2)
      assert_that(result.all_success_results.size).equals(2)
      assert_that(result.all_failure_results.size).equals(0)

      result.capture_for([false, nil].sample)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(1)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(1)
      assert_that(result.all_failure_results.size).equals(2)

      result = unit_class.success

      # Test the default built capture exception.
      exception =
        assert_that(-> {
          result.capture_for!(failure1)
        }).raises(MuchResult::Error)
      assert_that(exception.message).equals(failure1.description)
      assert_that(exception.backtrace).equals(failure1.backtrace)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(1)
      assert_that(result.success_sub_results.size).equals(0)
      assert_that(result.failure_sub_results.size).equals(1)
      assert_that(result.all_results.size).equals(2)
      assert_that(result.all_success_results.size).equals(0)
      assert_that(result.all_failure_results.size).equals(2)

      # Test that we prefer any set `result.exception` over the default built
      # capture exception.
      exception =
        assert_that(-> {
          result.capture_for!(failure2)
        }).raises(failure2.exception.class)
      assert_that(exception.message).equals(failure2.exception.message)
      assert_that(exception.backtrace).equals(failure2.exception.backtrace)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(0)
      assert_that(result.failure_sub_results.size).equals(2)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(0)
      assert_that(result.all_failure_results.size).equals(3)
    end

    should "capture MuchResults from an Array as sub-results" do
      subject.capture_for_all([unit_class.success, unit_class.failure])
      assert_that(subject.success?).is_false
      assert_that(subject.sub_results.size).equals(2)
      assert_that(subject.success_sub_results.size).equals(1)
      assert_that(subject.failure_sub_results.size).equals(1)
      assert_that(subject.all_results.size).equals(3)
      assert_that(subject.all_success_results.size).equals(1)
      assert_that(subject.all_failure_results.size).equals(2)

      result = unit_class.success

      result.capture_for_all(
        [
          [true, Factory.integer, Factory.string].sample,
          [false, nil].sample
        ]
      )
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(1)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(1)
      assert_that(result.all_failure_results.size).equals(2)

      result = unit_class.success

      exception =
        assert_that(-> {
          result.capture_for_all!([failure1, failure2])
        }).raises(MuchResult::Error)
      assert_that(exception.message).equals(failure1.description)
      assert_that(exception.backtrace).equals(failure1.backtrace)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(0)
      assert_that(result.failure_sub_results.size).equals(2)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(0)
      assert_that(result.all_failure_results.size).equals(3)
    end

    should "capture MuchResults from a block as sub-results" do
      subject.capture { unit_class.success }
      assert_that(subject.success?).is_true
      assert_that(subject.sub_results.size).equals(1)
      assert_that(subject.success_sub_results.size).equals(1)
      assert_that(subject.failure_sub_results.size).equals(0)
      assert_that(subject.all_results.size).equals(2)
      assert_that(subject.all_success_results.size).equals(2)
      assert_that(subject.all_failure_results.size).equals(0)

      subject.capture { unit_class.failure }
      assert_that(subject.success?).is_false
      assert_that(subject.sub_results.size).equals(2)
      assert_that(subject.success_sub_results.size).equals(1)
      assert_that(subject.failure_sub_results.size).equals(1)
      assert_that(subject.all_results.size).equals(3)
      assert_that(subject.all_success_results.size).equals(1)
      assert_that(subject.all_failure_results.size).equals(2)

      result = unit_class.success

      result.capture { [true, Factory.integer, Factory.string].sample }
      assert_that(result.success?).is_true
      assert_that(result.sub_results.size).equals(1)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(0)
      assert_that(result.all_results.size).equals(2)
      assert_that(result.all_success_results.size).equals(2)
      assert_that(result.all_failure_results.size).equals(0)

      result.capture { [false, nil].sample }
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(1)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(1)
      assert_that(result.all_failure_results.size).equals(2)

      result = unit_class.success

      exception =
        assert_that(-> {
          result.capture! { failure1 }
        }).raises(MuchResult::Error)
      assert_that(exception.message).equals(failure1.description)
      assert_that(exception.backtrace).equals(failure1.backtrace)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(1)
      assert_that(result.success_sub_results.size).equals(0)
      assert_that(result.failure_sub_results.size).equals(1)
      assert_that(result.all_results.size).equals(2)
      assert_that(result.all_success_results.size).equals(0)
      assert_that(result.all_failure_results.size).equals(2)
    end

    should "capture MuchResults from a block from an Array as sub-results" do
      subject.capture_all { [unit_class.success, unit_class.failure] }
      assert_that(subject.success?).is_false
      assert_that(subject.sub_results.size).equals(2)
      assert_that(subject.success_sub_results.size).equals(1)
      assert_that(subject.failure_sub_results.size).equals(1)
      assert_that(subject.all_results.size).equals(3)
      assert_that(subject.all_success_results.size).equals(1)
      assert_that(subject.all_failure_results.size).equals(2)

      result = unit_class.success

      result.capture_all do
        [
          [true, Factory.integer, Factory.string].sample,
          [false, nil].sample
        ]
      end
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(1)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(1)
      assert_that(result.all_failure_results.size).equals(2)

      result = unit_class.success

      exception =
        assert_that(-> {
          result.capture_all! { [failure1, failure2] }
        }).raises(MuchResult::Error)
      assert_that(exception.message).equals(failure1.description)
      assert_that(exception.backtrace).equals(failure1.backtrace)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(0)
      assert_that(result.failure_sub_results.size).equals(2)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(0)
      assert_that(result.all_failure_results.size).equals(3)
    end

    should "convert itself to a MuchResult" do
      assert_that(subject.value).is_nil

      result = subject.to_much_result(value: value1)
      assert_that(result).is_the_same_as(subject)
      assert_that(subject.value).equals(value1)
    end
  end
end
