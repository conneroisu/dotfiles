// JavaScript example with comments
// This demonstrates comment removal and compression

/**
 * Calculate the factorial of a number
 * @param {number} n - The number to calculate factorial for
 * @returns {number} The factorial result
 */
function factorial(n) {
    // Base case: factorial of 0 or 1 is 1
    if (n <= 1) {
        return 1; // Return 1 for base case
    }
    
    /* Recursive case:
       n! = n * (n-1)! */
    return n * factorial(n - 1); // Recursive call
}

// Test the function
const result = factorial(5); // Should be 120
console.log(`Factorial of 5 is: ${result}`); // Output result

// More complex example with object
const mathUtils = {
    // Addition function
    add: (a, b) => a + b, // Simple arrow function
    
    /* Multiplication function
       with comments */
    multiply: function(a, b) {
        return a * b; // Return product
    }
};

// Export for use in other modules
export { factorial, mathUtils };