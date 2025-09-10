// Java example with comprehensive comments
// This demonstrates Java-specific comment handling

import java.util.*;
import java.util.stream.Collectors;

/**
 * A utility class for mathematical operations
 * Provides various statistical and mathematical functions
 */
public class MathUtils {
    
    // Private constructor to prevent instantiation
    private MathUtils() {
        throw new IllegalStateException("Utility class"); // Prevent instantiation
    }
    
    /**
     * Calculate the arithmetic mean of a list of numbers
     * @param numbers List of numbers to calculate mean for
     * @return The arithmetic mean as a double
     * @throws IllegalArgumentException if the list is empty
     */
    public static double calculateMean(List<Double> numbers) {
        // Check for empty input
        if (numbers == null || numbers.isEmpty()) {
            throw new IllegalArgumentException("Cannot calculate mean of empty list"); // Validation error
        }
        
        // Use stream to calculate sum and divide by count
        return numbers.stream()
                .mapToDouble(Double::doubleValue) // Convert to primitive double
                .average() // Calculate average
                .orElse(0.0); // Default value (shouldn't happen due to empty check)
    }
    
    /*
     * Calculate the median value of a list of numbers
     * The median is the middle value in a sorted list
     */
    public static double calculateMedian(List<Double> numbers) {
        // Validate input
        if (numbers == null || numbers.isEmpty()) {
            throw new IllegalArgumentException("Cannot calculate median of empty list"); // Validation
        }
        
        // Create sorted copy to avoid modifying original
        List<Double> sorted = new ArrayList<>(numbers); // Copy list
        Collections.sort(sorted); // Sort the copy
        
        int size = sorted.size(); // Get list size
        
        // Check if odd or even number of elements
        if (size % 2 == 1) {
            // Odd number: return middle element
            return sorted.get(size / 2); // Middle element
        } else {
            // Even number: return average of two middle elements
            int midIndex = size / 2; // Middle index
            return (sorted.get(midIndex - 1) + sorted.get(midIndex)) / 2.0; // Average of middle two
        }
    }
    
    /**
     * Calculate standard deviation of a list of numbers
     * Uses the population standard deviation formula
     * @param numbers List of numbers
     * @return Standard deviation as a double
     */
    public static double calculateStandardDeviation(List<Double> numbers) {
        // Calculate mean first
        double mean = calculateMean(numbers); // Get the mean
        
        // Calculate sum of squared differences
        double sumSquaredDifferences = numbers.stream()
                .mapToDouble(num -> Math.pow(num - mean, 2)) // Square the difference
                .sum(); // Sum all squared differences
        
        // Return square root of variance
        return Math.sqrt(sumSquaredDifferences / numbers.size()); // Population standard deviation
    }
    
    // Find minimum and maximum values in a list
    public static class MinMax {
        public final double min; // Minimum value
        public final double max; // Maximum value
        
        // Constructor for MinMax result
        public MinMax(double min, double max) {
            this.min = min; // Set minimum
            this.max = max; // Set maximum
        }
    }
    
    /**
     * Find the minimum and maximum values in a list
     * @param numbers List of numbers to analyze
     * @return MinMax object containing min and max values
     */
    public static MinMax findMinMax(List<Double> numbers) {
        // Validate input
        if (numbers == null || numbers.isEmpty()) {
            throw new IllegalArgumentException("Cannot find min/max of empty list"); // Validation
        }
        
        // Use streams to find min and max efficiently
        OptionalDouble minOpt = numbers.stream().mapToDouble(Double::doubleValue).min(); // Find minimum
        OptionalDouble maxOpt = numbers.stream().mapToDouble(Double::doubleValue).max(); // Find maximum
        
        // Return result (optionals should have values due to non-empty check)
        return new MinMax(minOpt.orElse(0.0), maxOpt.orElse(0.0)); // Create MinMax object
    }
    
    // Main method for demonstration
    public static void main(String[] args) {
        // Create test data
        List<Double> testNumbers = Arrays.asList(
                1.5, 2.3, 4.7, 3.1, 5.9, // First set of numbers
                2.8, 4.2, 6.1, 3.5, 1.9  // Second set of numbers
        );
        
        // Calculate and display statistics
        System.out.println("Test data: " + testNumbers); // Display input data
        
        /* Calculate basic statistics
           This demonstrates all the utility functions */
        double mean = calculateMean(testNumbers); // Calculate mean
        double median = calculateMedian(testNumbers); // Calculate median
        double stdDev = calculateStandardDeviation(testNumbers); // Calculate standard deviation
        MinMax minMax = findMinMax(testNumbers); // Find min and max
        
        // Display results with formatting
        System.out.printf("Mean: %.2f%n", mean); // Display mean
        System.out.printf("Median: %.2f%n", median); // Display median
        System.out.printf("Standard Deviation: %.2f%n", stdDev); // Display std dev
        System.out.printf("Min: %.2f, Max: %.2f%n", minMax.min, minMax.max); // Display min/max
    }
}