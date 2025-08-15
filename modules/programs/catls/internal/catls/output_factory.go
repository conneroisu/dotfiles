package catls

import "fmt"

// NewOutputFormatter creates an output formatter for the specified format.
func NewOutputFormatter(format OutputFormat) (OutputFormatter, error) {
	switch format {
	case OutputFormatXML:
		return NewXMLOutput(), nil
	case OutputFormatJSON:
		return NewJSONOutput(), nil
	case OutputFormatMarkdown:
		return NewMarkdownOutput(), nil
	default:
		return nil, fmt.Errorf("unsupported output format: %s", format)
	}
}

// GetSupportedFormats returns a list of all supported output formats.
func GetSupportedFormats() []string {
	return []string{
		OutputFormatXML.String(),
		OutputFormatJSON.String(),
		OutputFormatMarkdown.String(),
	}
}