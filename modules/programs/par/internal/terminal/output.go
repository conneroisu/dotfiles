package terminal

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

// OutputHandler handles terminal output streaming and formatting
type OutputHandler struct {
	showRealTime bool
}

// NewOutputHandler creates a new output handler
func NewOutputHandler(showRealTime bool) *OutputHandler {
	return &OutputHandler{
		showRealTime: showRealTime,
	}
}

// StreamOutput streams output from a reader to stdout with optional real-time display
func (h *OutputHandler) StreamOutput(reader io.Reader, jobName string) (string, error) {
	var output string
	scanner := bufio.NewScanner(reader)
	
	for scanner.Scan() {
		line := scanner.Text()
		output += line + "\n"
		
		if h.showRealTime {
			fmt.Printf("[%s] %s\n", jobName, line)
		}
	}
	
	if err := scanner.Err(); err != nil {
		return output, fmt.Errorf("error reading output: %w", err)
	}
	
	return output, nil
}

// FormatJobOutput formats output for a specific job
func (h *OutputHandler) FormatJobOutput(jobName, output string) string {
	return fmt.Sprintf("=== Output for %s ===\n%s\n=== End of %s ===\n", 
		jobName, output, jobName)
}

// WriteToFile writes output to a file
func (h *OutputHandler) WriteToFile(filename, content string) error {
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create output file: %w", err)
	}
	defer file.Close()
	
	_, err = file.WriteString(content)
	if err != nil {
		return fmt.Errorf("failed to write to output file: %w", err)
	}
	
	return nil
}