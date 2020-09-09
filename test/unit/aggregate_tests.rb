require "assert"
require "much-result/aggregate"

class MuchResult::Aggregate
  class UnitTests < Assert::Context
    desc "MuchResult::Aggregate"
    subject { unit_class }

    let(:unit_class) { MuchResult::Aggregate }

    let(:values1) {
      [Factory.value, Factory.value, Factory.value, Hash.new]
    }
    let(:hash_values1) {
      [Factory.hash_value, Factory.hash_value, Factory.hash_value]
    }

    should have_imeths :call

    should "build instances and call them" do
      Assert.stub_tap_on_call(subject, :new) { |instance, call|
        @instance_new_call = call
        Assert.stub(instance, :call) { @instance_called = true }
      }

      subject.call(values1)

      assert_that(@instance_new_call.args).equals([values1])
      assert_that(@instance_called).is_true
    end
  end

  class InitTests < UnitTests
    desc "when init"
    subject { unit_class.new(init_values) }

    let(:init_values) { [values1, hash_values1, [], nil].sample }

    should have_imeths :call
  end

  class CalledWithAnEmptyArrayTests < InitTests
    desc "and called with an empty Array"

    let(:init_values) { [] }
    # let(:init_values) { [[], nil, [nil, nil]].sample }

    should "return an empty Array" do
      assert_that(subject.call).equals([])
    end
  end

  class CalledWithASingleNonHashValueTests < InitTests
    desc "and called with single non-Hash value"

    let(:init_values) { [Factory.value, nil].sample }

    should "return the value wrapped in an Array" do
      assert_that(subject.call).equals([init_values])
    end
  end

  class CalledWithASingleHashValueTests < InitTests
    desc "and called with single Hash value"

    let(:value1) { [Factory.value, nil].sample }
    let(:init_values) { { value: value1 } }

    should "return the Hash with its values wrapped in an Array" do
      assert_that(subject.call).equals(value: [value1])
    end
  end

  class CalledWithAMixedValueArrayTests < InitTests
    desc "and called with a mixed-value Array"

    let(:init_values) { [nil, values1, [], { value: 1 }, nil] }

    should "combines the values into an Array, flattening any sub-Arrays" do
      assert_that(subject.call).equals([nil, *values1, { value: 1 }, nil])
    end
  end

  class CalledWithAnAllHashValueArrayTests < InitTests
    desc "and called with an all-Hash-value Array"

    let(:init_values) { [nil] + hash_values1 + [nil] }

    let(:expected_aggregate_value) {
      {
        value1: init_values.map { |hash| (hash || {})[:value1] },
        value2: {
          value1: init_values.map { |hash| (hash || {}).dig(:value2, :value1) },
          value2: init_values.map { |hash| (hash || {}).dig(:value2, :value2) }
        }
      }
    }

    should "recursively combine the hash values, removing any nils" do
      assert_that(subject.call).equals(expected_aggregate_value)
    end
  end
end
