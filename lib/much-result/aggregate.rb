require "much-result"

class MuchResult; end
class MuchResult::Aggregate
  def self.call(values)
    new(values).call
  end

  def initialize(values)
    @values = values
  end

  def call
    combine_values(@values)
  end

  private

  def combine_values(values)
    combine_in_a_collection(array_wrap(values))
  end

  def combine_in_a_collection(values)
    if all_hash_values?(values)
      values.
        reduce { |acc, value| combine_in_a_hash(acc, value) }.
        transform_values { |nested_values| combine_values(nested_values) }
    else
      array_wrap(
        values.reduce([]) { |acc, value| combine_in_an_array(acc, value) }
      )
    end
  end

  def combine_in_a_hash(hash1, hash2)
    ((h1 = hash1 || {}).keys + (h2 = hash2 || {}).keys).
      uniq.
      reduce({}) { |hash, key|
        hash[key] = combine_in_an_array(h1[key], h2[key])
        hash
      }
  end

  def combine_in_an_array(acc, other)
    array_wrap(acc) + array_wrap(other)
  end

  def array_wrap(value)
    value.kind_of?(Array) ? value : [value]
  end

  def all_hash_values?(values)
    (compacted = values.compact).reduce(compacted.any?) { |acc, value|
      acc && value.kind_of?(::Hash)
    }
  end
end
