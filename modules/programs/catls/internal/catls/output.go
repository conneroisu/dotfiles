package catls

import (
	"context"
	"fmt"
	"html"
)

// XMLOutput handles XML output formatting.
type XMLOutput struct{}

// NewXMLOutput creates a new XML output formatter.
func NewXMLOutput() *XMLOutput {
	return &XMLOutput{}
}

// WriteHeader writes the opening XML structure.
func (o *XMLOutput) WriteHeader(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	fmt.Println("<files>")
	return nil
}

// WriteFile writes a single processed file to XML output.
func (o *XMLOutput) WriteFile(ctx context.Context, file ProcessedFile, cfg *Config) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	return o.writeProcessedFile(file, cfg)
}

// WriteFooter writes the closing XML structure.
func (o *XMLOutput) WriteFooter(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	fmt.Println("</files>")
	return nil
}

// writeProcessedFile writes a processed file to XML format.
func (o *XMLOutput) writeProcessedFile(file ProcessedFile, cfg *Config) error {
	safePath := html.EscapeString(file.Info.RelPath)
	fmt.Printf("<file path=\"%s\">\n", safePath)

	if file.Error != nil {
		safeError := html.EscapeString(file.Error.Error())
		fmt.Printf("<error>%s</error>\n", safeError)
		fmt.Println("</file>")
		return nil
	}

	if file.Info.IsBinary {
		fmt.Println("<binary>true</binary>")
		fmt.Println("<content>[Binary file - contents not displayed]</content>")
	} else {
		if file.FileType != "" {
			fmt.Printf("<type>%s</type>\n", html.EscapeString(file.FileType))
		}

		if err := o.writeContent(file, cfg); err != nil {
			return err
		}
	}

	fmt.Println("</file>")
	return nil
}

// writeContent writes the content section of a file.
func (o *XMLOutput) writeContent(file ProcessedFile, cfg *Config) error {
	fmt.Println("<content>")

	for _, line := range file.Lines {
		if cfg.ShowLineNumbers {
			fmt.Printf("%4d| %s\n", line.LineNumber, line.Content)
		} else {
			fmt.Println(line.Content)
		}
	}

	if file.IsTruncated {
		remainingLines := file.TotalLines - len(file.Lines)
		if remainingLines > 0 {
			fmt.Printf("... (%d more lines)\n", remainingLines)
		}
	}

	fmt.Println("</content>")
	return nil
}