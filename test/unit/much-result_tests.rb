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

    should have_imeths :success, :failure

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
      assert_that(result.items.first.identifier).equals(identifier1)
      assert_that(result.description).equals(description1)
      assert_that(result.items.first.description).equals(description1)
      assert_that(result.backtrace).equals(backtrace1)
      assert_that(result.items.first.backtrace).equals(backtrace1)
      assert_that(result.items.first.value).equals(value1)

      exception = result.result_exception
      assert_that(exception).is_instance_of(MuchResult::Error)
      assert_that(exception.message).equals(description1)
      assert_that(exception.backtrace).equals(backtrace1)
    end
  end
end
