# MuchResult

API for managing the results of operations.

## Usage

Have services/methods return a MuchResult based on the whether an exception was raised or not:

```ruby
class PerformSomeOperation
  def self.call
    # Do something that could fail by raising an exception.
    MuchResult.success(message: "it worked!")
  rescue => exception
    MuchResult.failure(exception: exception)
  end
end

result = PerformSomeOperation.call

result.success?    # => true
result.failure?    # => false
result.message     # => "it worked!"
result.sub_results # => []
```

Have services/methods return a MuchResult based on a result value (i.e. "truthy" = success; "false-y" = failure):

```ruby
def perform_some_operation(success:)
  # Do something that could fail.
  MuchResult.for(success, message: "it ran :shrug:")
end

result = perform_some_operation(success: true)
result.success? # => true
result.failure? # => false
result.message  # => "it ran :shrug:"

result = perform_some_operation(success: false)
result.success? # => false
result.failure? # => true
result.message  # => "it ran :shrug:"

result = perform_some_operation(success: nil)
result.success? # => false
result.failure? # => true
result.message  # => "it ran :shrug:"
```

Set arbitrary values on MuchResults before or after they are created:

```ruby
result = MuchResult.success(message: "it worked!")
result.set(
  other_value1: "something else 1",
  other_value2: "something else 2"
)
result.message      # => "it worked!"
result.other_value1 # => "something else 1"
result.other_value2 # => "something else 2"
```

### Capture sub-Results

Capture MuchResults for sub-operations into a parent MuchResult:

```ruby
class PerformSomeOperation
  def self.call
    MuchResult.tap(description: "Do both parts") { |result|
      result          # => <MuchResult ...>
      result.success? # => true

      result.capture { do_part_1 }
      # OR you can use `capture_all` to capture from an Array of MuchResults

      # raise an Exception if failure
      result.capture! { do_part_2 }
      # OR you can use `capture_all!` to capture from an Array of MuchResults

      # set some arbitrary values b/c it worked.
      result.set(message: "it worked!")
    } # => result
  end

  def self.do_part_1
    MuchResult.failure(description: "Part 1")
  end

  def self.do_part_2
    MuchResult.success(description: "Part 2")
  end
end

result = PerformSomeOperation.call

result.success? # => true
result.message  # => "it worked!"

# Get just the immediate sub-results that were captured for the MuchResult.
result.sub_results # => [<MuchResult Part 1>, <MuchResult Part 2>]

# Get all MuchResults that make up this MuchResult (including those captured
# on all recursive sub-results).
result.all_results # => [result, <MuchResult Part 1>, <MuchResult Part 2>]

# Get aggregated values for each MuchResult that makes up this MuchResult.
result.get_for_sub_results(:description)
# => ["Part 1", "Part 2"]
result.get_for_success_sub_results(:description)
# => ["Part 2"]
result.get_for_failure_sub_results(:description)
# => ["Part 1"]

result.get_for_all_results(:description)
# => ["Do both parts", "Part 1", "Part 2"]
result.get_for_all_success_results(:description)
# => ["Part 2"]
result.get_for_all_failure_results(:description)
# => ["Do both parts", "Part 1"]
```

### Transactions

Run transactions capturing sub-Results:

```ruby
class PerformSomeOperation
  def self.call
    MuchResult.transaction(
      ActiveRecord::Base,
      value: "something",
      description: "Do both parts"
    ) { |transaction|
      transaction        # => <MuchResult::Transaction ...>
      transaction.result # => <MuchResult ...>

      # You can interact with a transaction as if it were a MuchResult.
      transaction.value    # => "something"
      transaction.success? # => true

      transaction.capture { do_part_1 }
      # OR you can use `capture_all` to capture from an Array of MuchResults

      # raise an Exception if failure (which will rollback the transaction)
      transaction.capture! { do_part_2 }
      # OR you can use `capture_all!` to capture from an Array of MuchResults

      # manually rollback the transaction if needed
      # (stops processing and doesn't commit the transaction)
      transaction.rollback if rollback_needed?

      # manually halt the transaction if needed
      # (stops processing and commits the transaction)
      transaction.halt if halt_needed?

      # set some arbitrary values b/c it worked.
      transaction.set(message: "it worked!")
    } # => transaction.result
  end

  def self.do_part_1
    MuchResult.failure(description: "Part 1")
  end

  def self.do_part_2
    MuchResult.success(description: "Part 2")
  end

  def rollback_needed?
    false
  end

  def halt_needed?
    false
  end
end

result = PerformSomeOperation.call

result.success? # => true
result.message  # => "it worked!"

result.much_result_transaction_rolled_back # => false
result.much_result_transaction_halted      # => false

# Get just the immediate sub-results that were captured for the MuchResult.
result.sub_results # => [<MuchResult Part 1>, <MuchResult Part 2>]

# Get all MuchResults that make up this MuchResult (including those captured
# on all recursive sub-results).
result.all_results # => [result, <MuchResult Part 1>, <MuchResult Part 2>]

# Get aggregated values for each MuchResult that makes up this MuchResult.
result.get_for_sub_results(:description)
# => ["Part 1", "Part 2"]
result.get_for_success_sub_results(:description)
# => ["Part 2"]
result.get_for_failure_sub_results(:description)
# => ["Part 1"]

result.get_for_all_results(:description)
# => ["Do both parts", "Part 1", "Part 2"]
result.get_for_all_success_results(:description)
# => ["Part 2"]
result.get_for_all_failure_results(:description)
# => ["Do both parts", "Part 1"]
```

Note: MuchResult::Transactions are designed to delegate to their MuchResult. You can interact with a MuchResult::Transaction as if it were a MuchResult.

## Installation

Add this line to your application's Gemfile:

    gem "much-result"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install much-result

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
