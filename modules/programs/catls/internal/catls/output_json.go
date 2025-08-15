package catls

import (
	"context"
	"encoding/json"
	"os"
)

// JSONOutput handles JSON output formatting.
type JSONOutput struct {
	files []JSONFile
}

// JSONFile represents a file in JSON format.
type JSONFile struct {
	Path       string     `json:"path"`
	Type       string     `json:"type,omitempty"`
	Binary     bool       `json:"binary"`
	Error      *string    `json:"error,omitempty"`
	Lines      []JSONLine `json:"lines,omitempty"`
	TotalLines int        `json:"totalLines"`
	Truncated  bool       `json:"truncated"`
}

// JSONLine represents a line of content with its number.
type JSONLine struct {
	Number  int    `json:"number"`
	Content string `json:"content"`
}

// NewJSONOutput creates a new JSON output formatter.
func NewJSONOutput() *JSONOutput {
	return &JSONOutput{
		files: make([]JSONFile, 0),
	}
}

// WriteHeader writes the opening JSON structure (no-op for JSON).
func (o *JSONOutput) WriteHeader(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	// JSON requires complete structure, so we don't write anything here
	return nil
}

// WriteFile accumulates a processed file for later JSON output.
func (o *JSONOutput) WriteFile(ctx context.Context, file ProcessedFile, cfg *Config) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	jsonFile := JSONFile{
		Path:       file.Info.RelPath,
		Binary:     file.Info.IsBinary,
		TotalLines: file.TotalLines,
		Truncated:  file.IsTruncated,
	}

	// Set file type if available and not binary
	if !file.Info.IsBinary && file.FileType != "" {
		jsonFile.Type = file.FileType
	}

	// Handle errors
	if file.Error != nil {
		errorMsg := file.Error.Error()
		jsonFile.Error = &errorMsg
	} else if !file.Info.IsBinary {
		// Add lines for non-binary files without errors
		jsonFile.Lines = make([]JSONLine, len(file.Lines))
		for i, line := range file.Lines {
			jsonFile.Lines[i] = JSONLine{
				Number:  line.LineNumber,
				Content: line.Content,
			}
		}
	}

	o.files = append(o.files, jsonFile)
	return nil
}

// WriteFooter writes the complete JSON structure.
func (o *JSONOutput) WriteFooter(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	output := struct {
		Files []JSONFile `json:"files"`
	}{
		Files: o.files,
	}

	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	return encoder.Encode(output)
}