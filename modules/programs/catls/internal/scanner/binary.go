package scanner

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// BinaryDetector defines the interface for detecting binary files.
type BinaryDetector interface {
	IsBinary(path string) bool
}

// FileBinaryDetector implements BinaryDetector using file command and byte analysis.
type FileBinaryDetector struct{}

// IsBinary detects if a file is binary using the file command as primary method
// and falls back to byte analysis.
func (d *FileBinaryDetector) IsBinary(path string) bool {
	// Try using the file command first
	cmd := exec.Command("file", path)
	output, err := cmd.Output()
	if err == nil {
		return !strings.Contains(strings.ToLower(string(output)), "text")
	}

	// Fallback to byte analysis
	return d.isBinaryByBytes(path)
}

// isBinaryByBytes checks for null bytes in the first 1024 bytes of a file.
func (d *FileBinaryDetector) isBinaryByBytes(path string) bool {
	file, err := os.Open(path)
	if err != nil {
		return true // Assume binary if we can't read it
	}
	defer func() {
		if closeErr := file.Close(); closeErr != nil {
			// Log close error - in a real app you'd use a proper logger
			fmt.Fprintf(os.Stderr, "Warning: failed to close file %s: %v\n", path, closeErr)
		}
	}()

	chunk := make([]byte, 1024)
	n, err := file.Read(chunk)
	if err != nil {
		return true
	}

	return bytes.Contains(chunk[:n], []byte{0})
}