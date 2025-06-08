package prompts

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"
)

// TemplateVars contains variables for template processing
type TemplateVars struct {
	ProjectName    string
	TaskName       string
	Description    string
	BranchName     string
	WorktreePath   string
	Instructions   string
	ExpectedOutcome string
	Custom         map[string]interface{}
}

// Processor handles template processing
type Processor struct {
	funcMap template.FuncMap
}

// NewProcessor creates a new template processor
func NewProcessor() *Processor {
	funcMap := template.FuncMap{
		"upper": func(s string) string {
			return strings.ToUpper(s)
		},
		"lower": func(s string) string {
			return strings.ToLower(s)
		},
		"title": func(s string) string {
			return strings.Title(s)
		},
		"default": func(def, val string) string {
			if val == "" {
				return def
			}
			return val
		},
	}

	return &Processor{
		funcMap: funcMap,
	}
}

// Process processes a template with the given variables
func (p *Processor) Process(templateContent string, vars TemplateVars) (string, error) {
	tmpl, err := template.New("prompt").Funcs(p.funcMap).Parse(templateContent)
	if err != nil {
		return "", fmt.Errorf("failed to parse template: %w", err)
	}

	var buf bytes.Buffer
	err = tmpl.Execute(&buf, vars)
	if err != nil {
		return "", fmt.Errorf("failed to execute template: %w", err)
	}

	return buf.String(), nil
}

// ProcessPrompt processes a prompt, applying templates if needed
func (p *Processor) ProcessPrompt(prompt *Prompt, vars TemplateVars) (string, error) {
	if !prompt.IsTemplate {
		return prompt.Content, nil
	}

	return p.Process(prompt.Content, vars)
}