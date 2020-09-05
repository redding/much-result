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

      result_result = subject.for(true_result, value: value1)
      assert_that(result_result).is_the_same_as(true_result)
      assert_that(result_result.value).equals(value1)
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
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.success }

    should have_imeths :description, :backtrace, :set
    should have_imeths :success?, :failure?
    should have_imeths :capture, :capture!, :capture_exception
    should have_imeths :sub_results, :success_sub_results, :failure_sub_results
    should have_imeths :all_results, :all_success_results, :all_failure_results

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

    should "allow setting arbitrary values" do
      assert_that(subject.other_value).is_nil

      subject.set(other_value: value1)
      assert_that(subject.other_value).equals(value1)
    end

    should "allow capturing other MuchResults as results" do
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
      result.capture! { unit_class.success }
      assert_that(result.success?).is_true
      assert_that(result.sub_results.size).equals(1)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(0)
      assert_that(result.all_results.size).equals(2)
      assert_that(result.all_success_results.size).equals(2)
      assert_that(result.all_failure_results.size).equals(0)

      # Test the default built capture exception.
      failure1 = unit_class.failure(description: Factory.string)
      exception =
        assert_that(-> { result.capture! { failure1 } }).
          raises(MuchResult::Error)
      assert_that(exception.message).equals(failure1.description)
      assert_that(exception.backtrace).equals(failure1.backtrace)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(2)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(1)
      assert_that(result.all_results.size).equals(3)
      assert_that(result.all_success_results.size).equals(1)
      assert_that(result.all_failure_results.size).equals(2)

      # Test that we prefer any set `result.exception` over the default built
      # capture exception.
      failure2 = unit_class.failure(exception: StandardError.new(Factory.string))
      exception =
        assert_that(-> { result.capture! { failure2 } }).
          raises(failure2.exception.class)
      assert_that(exception.message).equals(failure2.exception.message)
      assert_that(exception.backtrace).equals(failure2.exception.backtrace)
      assert_that(result.success?).is_false
      assert_that(result.sub_results.size).equals(3)
      assert_that(result.success_sub_results.size).equals(1)
      assert_that(result.failure_sub_results.size).equals(2)
      assert_that(result.all_results.size).equals(4)
      assert_that(result.all_success_results.size).equals(1)
      assert_that(result.all_failure_results.size).equals(3)
    end
  end
end
