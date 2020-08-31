# MuchResult

API for managing the results of operations.

## Usage


```ruby
def perform_some_operation
  # Do something that could fail by raising an exception.
  MuchResult.success(value: "it worked!")
rescue => error
  MuchResult.failure(exception: error)
end

result = perform_some_operation

result.success? # => true
result.failure? # => false
result.items    # => [<MuchResult::Item ...>]
result.value    # => "it worked!"

result.set(
  other_value1: "something else 1",
  other_value2: "something else 2"
)
result.other_value1 # => "something else 1"
result.other_value2 # => "something else 2"
```

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
