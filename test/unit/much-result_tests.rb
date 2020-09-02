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

      assert_that(result.results).equals([result])
      assert_that(result.success_results).equals([result])
      assert_that(result.failure_results).equals([])
    end

    should "build failure instances" do
      result = subject.failure

      assert_that(result.success?).is_false
      assert_that(result.failure?).is_true

      assert_that(result.results).equals([result])
      assert_that(result.success_results).equals([])
      assert_that(result.failure_results).equals([result])
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
          assert_that(result.results.size).equals(1)
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
  end

  class InitTests < UnitTests
    desc "when init"
    subject { result1 }

    let(:result1) { unit_class.success }

    should have_imeths :description, :backtrace, :set
    should have_imeths :success?, :failure?
    should have_imeths :capture, :capture!, :result_exception
    should have_imeths :results, :success_results, :failure_results

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

      exception = result.result_exception
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
      assert_that(subject.results.size).equals(2)
      assert_that(subject.success_results.size).equals(2)
      assert_that(subject.failure_results.size).equals(0)

      subject.capture { unit_class.failure }
      assert_that(subject.success?).is_false
      assert_that(subject.results.size).equals(3)
      assert_that(subject.success_results.size).equals(1)
      assert_that(subject.failure_results.size).equals(2)

      result = unit_class.success
      result.capture { [true, Factory.integer, Factory.string].sample }
      assert_that(result.success?).is_true
      assert_that(result.results.size).equals(2)
      assert_that(result.success_results.size).equals(2)
      assert_that(result.failure_results.size).equals(0)

      result.capture { [false, nil].sample }
      assert_that(result.success?).is_false
      assert_that(result.results.size).equals(3)
      assert_that(result.success_results.size).equals(1)
      assert_that(result.failure_results.size).equals(2)

      result = unit_class.success
      result.capture! { unit_class.success }
      assert_that(result.success?).is_true
      assert_that(result.results.size).equals(2)
      assert_that(result.success_results.size).equals(2)
      assert_that(result.failure_results.size).equals(0)

      assert_that(-> { result.capture! { unit_class.failure } }).
        raises(MuchResult::Error)
      assert_that(result.success?).is_false
      assert_that(result.results.size).equals(3)
      assert_that(result.success_results.size).equals(1)
      assert_that(result.failure_results.size).equals(2)
    end
  end
end
