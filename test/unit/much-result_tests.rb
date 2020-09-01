require "assert"
require "much-result"

class MuchResult
  class UnitTests < Assert::Context
    desc "MuchResult"
    subject { unit_class }

    setup do
      Assert.stub_tap_on_call(MuchResult::Item, :success) { |item, call|
        @success_result = item
        @success_item_call = call
      }
      Assert.stub_tap_on_call(MuchResult::Item, :failure) { |item, call|
        @failure_result = item
        @failure_item_call = call
      }
    end

    let(:unit_class) { MuchResult }

    let(:identifier1) { Factory.string }
    let(:description1) { Factory.string }
    let(:backtrace1) { Factory.backtrace }
    let(:value1) { Factory.value }

    should have_imeths :success, :failure, :for

    should "build success instances" do
      result = subject.success

      assert_that(result.success?).is_true
      assert_that(result.failure?).is_false

      assert_that(result.items).equals([@success_result])
      assert_that(result.success_items).equals(result.items)
      assert_that(result.failure_items).equals([])
    end

    should "build failure instances" do
      result = subject.failure

      assert_that(result.success?).is_false
      assert_that(result.failure?).is_true

      assert_that(result.items).equals([@failure_result])
      assert_that(result.success_items).equals([])
      assert_that(result.failure_items).equals(result.items)
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
          assert_that(result.items.size).equals(0)
        }
      assert_that(tap_result).is_the_same_as(yielded_result)
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { result1 }

    let(:result1) { unit_class.success }

    should have_imeths :success?, :failure?
    should have_imeths :description, :backtrace, :result_exception
    should have_imeths :items, :success_items, :failure_items

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
      assert_that(result.items.first.identifier).equals(identifier1)
      assert_that(result.description).equals(description1)
      assert_that(result.items.first.description).equals(description1)
      assert_that(result.backtrace).equals(backtrace1)
      assert_that(result.items.first.backtrace).equals(backtrace1)
      assert_that(result.value).equals(value1)
      assert_that(result.items.first.value).equals(value1)

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

    should "allow capturing other MuchResults as items" do
      subject.capture { unit_class.success }
      assert_that(subject.success?).is_true
      assert_that(subject.items.size).equals(2)
      assert_that(subject.success_items.size).equals(2)
      assert_that(subject.failure_items.size).equals(0)

      subject.capture { unit_class.failure }
      assert_that(subject.success?).is_false
      assert_that(subject.items.size).equals(3)
      assert_that(subject.success_items.size).equals(2)
      assert_that(subject.failure_items.size).equals(1)

      result = unit_class.success
      result.capture { [true, Factory.integer, Factory.string].sample }
      assert_that(result.success?).is_true
      assert_that(result.items.size).equals(2)
      assert_that(result.success_items.size).equals(2)
      assert_that(result.failure_items.size).equals(0)

      result.capture { [false, nil].sample }
      assert_that(result.success?).is_false
      assert_that(result.items.size).equals(3)
      assert_that(result.success_items.size).equals(2)
      assert_that(result.failure_items.size).equals(1)

      result = unit_class.success
      result.capture! { unit_class.success }
      assert_that(result.success?).is_true
      assert_that(result.items.size).equals(2)
      assert_that(result.success_items.size).equals(2)
      assert_that(result.failure_items.size).equals(0)

      assert_that(-> { result.capture! { unit_class.failure } }).
        raises(MuchResult::Error)
      assert_that(result.success?).is_false
      assert_that(result.items.size).equals(3)
      assert_that(result.success_items.size).equals(2)
      assert_that(result.failure_items.size).equals(1)
    end
  end
end
