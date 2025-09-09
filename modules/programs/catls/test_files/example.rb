# Ruby example - comments removed, whitespace preserved
# This demonstrates Ruby-specific comment handling

=begin
This is a multi-line comment in Ruby
It should be handled by tree-sitter
=end

class Calculator
  # Initialize with optional precision
  def initialize(precision = 2)
    @precision = precision # Store precision for rounding
  end
  
  # Add two numbers with precision rounding
  def add(a, b)
    result = a + b # Perform addition
    round_result(result) # Apply precision
  end
  
  # Subtract two numbers with precision rounding
  def subtract(a, b)
    result = a - b # Perform subtraction
    round_result(result) # Apply precision
  end
  
  =begin
  Multiply two numbers
  Returns rounded result
  =end
  def multiply(a, b)
    result = a * b # Perform multiplication
    round_result(result) # Apply precision
  end
  
  # Divide two numbers with error handling
  def divide(a, b)
    # Check for division by zero
    raise ArgumentError, "Cannot divide by zero" if b.zero?
    
    result = a.to_f / b # Perform division (ensure float)
    round_result(result) # Apply precision
  end
  
  private
  
  # Round result to specified precision
  def round_result(value)
    value.round(@precision) # Apply rounding
  end
end

# Demonstrate the calculator functionality
if __FILE__ == $0
  calc = Calculator.new(3) # Create calculator with 3 decimal places
  
  # Test basic operations
  puts "Addition: #{calc.add(10.5, 3.7)}" # Should be 14.2
  puts "Subtraction: #{calc.subtract(10.5, 3.7)}" # Should be 6.8
  puts "Multiplication: #{calc.multiply(10.5, 3.7)}" # Should be 38.85
  puts "Division: #{calc.divide(10.5, 3.7)}" # Should be 2.838
  
  # Test arrays and blocks
  numbers = [1, 2, 3, 4, 5] # Test array
  
  # Calculate sum using reduce
  sum = numbers.reduce(0) do |acc, num|
    acc + num # Add to accumulator
  end
  
  puts "Sum of array: #{sum}" # Should be 15
  
  # Calculate squares using map
  squares = numbers.map { |n| n * n } # Square each number
  puts "Squares: #{squares}" # Should be [1, 4, 9, 16, 25]
end