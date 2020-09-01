require "assert"
require "much-result/item"

class MuchResult::Item
  class UnitTests < Assert::Context
    desc "MuchResult::Item"
    subject { unit_class }

    let(:unit_class) { MuchResult::Item }

    let(:identifier1) { Factory.string }
    let(:description1) { Factory.string }
    let(:backtrace1) { Factory.backtrace }
    let(:value1) { Factory.value }

    should have_imeths :success, :failure, :for

    should "build success instances" do
      item = subject.success

      assert_that(item.result).equals(MuchResult::SUCCESS)
      assert_that(item.success?).is_true
      assert_that(item.failure?).is_false

      assert_that(item.items).equals([item])
      assert_that(item.success_items).equals(item.items)
      assert_that(item.failure_items).equals([])
    end

    should "build failure instances" do
      item = subject.failure

      assert_that(item.result).equals(MuchResult::FAILURE)
      assert_that(item.success?).is_false
      assert_that(item.failure?).is_true

      assert_that(item.items).equals([item])
      assert_that(item.success_items).equals([])
      assert_that(item.failure_items).equals(item.items)
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
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { item1 }

    let(:item1) { unit_class.success }

    should have_imeths :success?, :failure?
    should have_imeths :identifier, :description, :backtrace, :result_exception
    should have_imeths :items, :success_items, :failure_items

    should "know its attributes" do
      assert_that(subject.identifier).is_nil
      assert_that(subject.description).is_nil
      assert_that(subject.backtrace).is_not_nil
      assert_that(subject.backtrace).is_not_empty

      item =
        unit_class.success(
          identifier: identifier1,
          description: description1,
          backtrace: backtrace1,
          value: value1
        )
      assert_that(item.identifier).equals(identifier1)
      assert_that(item.description).equals(description1)
      assert_that(item.backtrace).equals(backtrace1)
      assert_that(item.value).equals(value1)

      exception = item.result_exception
      assert_that(exception).is_instance_of(MuchResult::Error)
      assert_that(exception.message).equals(description1)
      assert_that(exception.backtrace).equals(backtrace1)
    end
  end
end
