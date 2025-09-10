# Python example - comments should be removed but whitespace preserved
# This file demonstrates Python-specific handling

"""
Module docstring - this is a string literal, not a comment
Should be preserved in the output
"""

def calculate_fibonacci(n):
    """Calculate the nth Fibonacci number using iterative approach.
    
    Args:
        n (int): The position in the Fibonacci sequence
        
    Returns:
        int: The nth Fibonacci number
    """
    # Handle edge cases
    if n <= 0:
        return 0  # First Fibonacci number
    elif n == 1:
        return 1  # Second Fibonacci number
    
    # Initialize variables for iteration
    a, b = 0, 1  # Start with first two numbers
    
    # Calculate iteratively
    for i in range(2, n + 1):
        # Update values for next iteration
        a, b = b, a + b  # Parallel assignment
    
    return b  # Return the result


class FibonacciGenerator:
    """A class to generate Fibonacci numbers."""
    
    def __init__(self):
        # Initialize the generator state
        self.cache = {0: 0, 1: 1}  # Cache for memoization
    
    def get_fibonacci(self, n):
        """Get the nth Fibonacci number with memoization."""
        # Check if already calculated
        if n in self.cache:
            return self.cache[n]  # Return cached result
        
        # Calculate and cache the result
        result = self.get_fibonacci(n - 1) + self.get_fibonacci(n - 2)
        self.cache[n] = result  # Store in cache
        
        return result


# Test the functions
if __name__ == "__main__":
    # Test the iterative function
    print(f"Fibonacci(10) = {calculate_fibonacci(10)}")  # Should be 55
    
    # Test the class-based approach
    fib_gen = FibonacciGenerator()
    print(f"Fibonacci(15) = {fib_gen.get_fibonacci(15)}")  # Should be 610