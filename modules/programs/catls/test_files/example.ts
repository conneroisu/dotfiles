// TypeScript example with type annotations and comments
// This demonstrates TypeScript-specific comment handling

/**
 * Interface for representing a user in the system
 * Contains basic user information
 */
interface User {
    id: number;        // Unique identifier
    name: string;      // User's display name
    email: string;     // User's email address
    isActive: boolean; // Whether the user account is active
}

/**
 * Generic response wrapper for API calls
 * @template T The type of data being returned
 */
interface ApiResponse<T> {
    success: boolean;    // Whether the request succeeded
    data?: T;           // The response data (optional)
    error?: string;     // Error message if failed (optional)
    timestamp: number;  // Response timestamp
}

// User service class for managing user operations
class UserService {
    private users: Map<number, User> = new Map(); // Internal user storage
    private nextId: number = 1; // Auto-increment ID counter
    
    /**
     * Create a new user in the system
     * @param name - The user's name
     * @param email - The user's email
     * @returns Promise resolving to API response with user data
     */
    async createUser(name: string, email: string): Promise<ApiResponse<User>> {
        try {
            // Validate input parameters
            if (!name.trim() || !email.trim()) {
                return {
                    success: false,
                    error: "Name and email are required", // Validation error
                    timestamp: Date.now()
                };
            }
            
            // Create new user object
            const newUser: User = {
                id: this.nextId++,     // Assign and increment ID
                name: name.trim(),      // Clean up name
                email: email.trim(),    // Clean up email
                isActive: true          // Default to active
            };
            
            // Store user in memory
            this.users.set(newUser.id, newUser); // Add to storage
            
            /* Return successful response
               with the created user */
            return {
                success: true,
                data: newUser,          // Return created user
                timestamp: Date.now()   // Current timestamp
            };
        } catch (error) {
            // Handle any unexpected errors
            return {
                success: false,
                error: "Failed to create user", // Generic error message
                timestamp: Date.now()
            };
        }
    }
    
    /**
     * Get a user by their ID
     * @param id - The user's ID
     * @returns Promise resolving to API response with user data
     */
    async getUserById(id: number): Promise<ApiResponse<User>> {
        // Look up user in storage
        const user = this.users.get(id); // Get user from map
        
        if (!user) {
            // User not found
            return {
                success: false,
                error: `User with ID ${id} not found`, // Not found error
                timestamp: Date.now()
            };
        }
        
        // Return found user
        return {
            success: true,
            data: user,             // Return found user
            timestamp: Date.now()   // Current timestamp
        };
    }
    
    // Get all active users
    async getActiveUsers(): Promise<ApiResponse<User[]>> {
        // Filter active users from storage
        const activeUsers = Array.from(this.users.values())
            .filter(user => user.isActive); // Only active users
        
        return {
            success: true,
            data: activeUsers,      // Return active users array
            timestamp: Date.now()   // Current timestamp
        };
    }
}

// Demonstration of the user service
async function demonstrateUserService(): Promise<void> {
    const userService = new UserService(); // Create service instance
    
    // Create some test users
    const user1Response = await userService.createUser("Alice Johnson", "alice@example.com");
    const user2Response = await userService.createUser("Bob Smith", "bob@example.com");
    
    // Log creation results
    console.log("Created user 1:", user1Response); // First user result
    console.log("Created user 2:", user2Response); // Second user result
    
    /* Fetch and display user by ID
       This demonstrates the retrieval functionality */
    if (user1Response.success && user1Response.data) {
        const fetchedUser = await userService.getUserById(user1Response.data.id);
        console.log("Fetched user:", fetchedUser); // Display fetched user
    }
    
    // Get all active users
    const activeUsers = await userService.getActiveUsers();
    console.log("Active users:", activeUsers); // Display all active users
}

// Run the demonstration
demonstrateUserService().catch(console.error); // Handle any errors