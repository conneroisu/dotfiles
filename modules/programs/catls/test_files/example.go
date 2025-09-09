// Go example with comments
// Package demonstrates Go-specific comment handling

package main

import (
	"fmt"     // Standard format package
	"strconv" // String conversion utilities
)

/*
Person represents a person with basic information.
This is a struct comment that should be removed.
*/
type Person struct {
	Name string // Person's name
	Age  int    // Person's age
}

// NewPerson creates a new Person instance
// This is a constructor-like function
func NewPerson(name string, age int) *Person {
	return &Person{
		Name: name, // Set the name
		Age:  age,  // Set the age
	}
}

/*
String returns a string representation of the Person.
This implements the Stringer interface.
*/
func (p *Person) String() string {
	// Format the person information
	return fmt.Sprintf("Person{Name: %s, Age: %d}", p.Name, p.Age) // Return formatted string
}

// IsAdult checks if the person is an adult (18 or older)
func (p *Person) IsAdult() bool {
	return p.Age >= 18 // Adult threshold is 18
}

// main function demonstrates the Person struct
func main() {
	// Create a new person
	person := NewPerson("Alice", 25) // Create Alice
	
	/* Display person information
	   This shows the string representation */
	fmt.Println(person.String()) // Print person info
	
	// Check if adult
	if person.IsAdult() {
		fmt.Println(person.Name + " is an adult") // Adult message
	} else {
		fmt.Println(person.Name + " is a minor") // Minor message
	}
	
	// Convert age to string for demonstration
	ageStr := strconv.Itoa(person.Age) // Convert int to string
	fmt.Printf("Age as string: %s\n", ageStr) // Print age string
}