require "assert/factory"

module Factory
  extend Assert::Factory

  def self.value
    [Factory.integer, Factory.string, Object.new].sample
  end

  def self.backtrace
    Factory.integer(3).times.map{ Factory.string }
  end
end
