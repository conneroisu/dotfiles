// Rust example with various comment types
// This demonstrates Rust-specific comment handling

use std::collections::HashMap; // Import HashMap for caching

/// A struct to represent a point in 2D space
/// This is a documentation comment
#[derive(Debug, Clone, PartialEq)]
pub struct Point {
    pub x: f64, // X coordinate
    pub y: f64, // Y coordinate
}

impl Point {
    /// Create a new Point instance
    /// 
    /// # Arguments
    /// * `x` - The x coordinate
    /// * `y` - The y coordinate
    pub fn new(x: f64, y: f64) -> Self {
        Point { x, y } // Return new point
    }
    
    /// Calculate the distance from origin
    /// Formula: sqrt(x² + y²)
    pub fn distance_from_origin(&self) -> f64 {
        // Use Pythagorean theorem
        (self.x * self.x + self.y * self.y).sqrt() // Calculate distance
    }
    
    /*
     * Calculate distance between two points
     * This is a multi-line comment
     */
    pub fn distance_to(&self, other: &Point) -> f64 {
        let dx = self.x - other.x; // Difference in x
        let dy = self.y - other.y; // Difference in y
        
        // Calculate distance using Pythagorean theorem
        (dx * dx + dy * dy).sqrt() // Return distance
    }
}

/// A cache for storing calculated distances
pub struct DistanceCache {
    cache: HashMap<(String, String), f64>, // Internal cache storage
}

impl DistanceCache {
    /// Create a new distance cache
    pub fn new() -> Self {
        DistanceCache {
            cache: HashMap::new(), // Initialize empty cache
        }
    }
    
    /// Get cached distance or calculate if not cached
    pub fn get_distance(&mut self, p1: &Point, p2: &Point) -> f64 {
        // Create cache key from point coordinates
        let key = (
            format!("({}, {})", p1.x, p1.y), // First point as string
            format!("({}, {})", p2.x, p2.y), // Second point as string
        );
        
        /* Check if distance is already cached
           If not, calculate and store it */
        *self.cache.entry(key).or_insert_with(|| {
            p1.distance_to(p2) // Calculate distance
        })
    }
}

// Main function to demonstrate the functionality
fn main() {
    // Create some test points
    let origin = Point::new(0.0, 0.0); // Origin point
    let point_a = Point::new(3.0, 4.0); // Point A
    let point_b = Point::new(1.0, 1.0); // Point B
    
    // Calculate distances
    println!("Point A: {:?}", point_a); // Print point A
    println!("Distance from origin: {:.2}", point_a.distance_from_origin()); // Distance to origin
    
    /* Test the distance cache functionality
       This demonstrates caching behavior */
    let mut cache = DistanceCache::new(); // Create cache
    let distance = cache.get_distance(&point_a, &point_b); // Get cached distance
    println!("Distance A to B: {:.2}", distance); // Print distance
}