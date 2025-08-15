package catls

import "context"

// OutputFormatter defines the interface for different output formats.
type OutputFormatter interface {
	// WriteHeader writes the opening structure for the output format.
	WriteHeader(ctx context.Context) error

	// WriteFile writes a single processed file to the output.
	WriteFile(ctx context.Context, file ProcessedFile, cfg *Config) error

	// WriteFooter writes the closing structure for the output format.
	WriteFooter(ctx context.Context) error
}

// OutputFormat represents supported output formats.
type OutputFormat string

const (
	OutputFormatXML      OutputFormat = "xml"
	OutputFormatJSON     OutputFormat = "json"
	OutputFormatMarkdown OutputFormat = "markdown"
)

// String returns the string representation of the output format.
func (f OutputFormat) String() string {
	return string(f)
}

// IsValid checks if the output format is supported.
func (f OutputFormat) IsValid() bool {
	switch f {
	case OutputFormatXML, OutputFormatJSON, OutputFormatMarkdown:
		return true
	default:
		return false
	}
}