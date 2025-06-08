package prompts

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"
)

// TemplateVars represents template variable substitutions
type TemplateVars map[string]string

// ProcessTemplate processes a prompt template with provided variables
func ProcessTemplate(prompt *Prompt, vars TemplateVars) (string, error) {
	if !prompt.Template {
		return prompt.Content, nil
	}

	// Validate required variables
	err := validateVariables(prompt, vars)
	if err != nil {
		return "", err
	}

	// Apply defaults for missing variables
	finalVars := applyDefaults(prompt, vars)

	// Process the template
	tmpl, err := template.New(prompt.Name).Parse(prompt.Content)
	if err != nil {
		return "", fmt.Errorf("failed to parse template: %w", err)
	}

	var buf bytes.Buffer
	err = tmpl.Execute(&buf, finalVars)
	if err != nil {
		return "", fmt.Errorf("failed to execute template: %w", err)
	}

	return buf.String(), nil
}

// validateVariables checks that all required variables are provided
func validateVariables(prompt *Prompt, vars TemplateVars) error {
	var missing []string

	for _, variable := range prompt.Variables {
		if variable.Required {
			if _, exists := vars[variable.Name]; !exists {
				missing = append(missing, variable.Name)
			}
		}
	}

	if len(missing) > 0 {
		return fmt.Errorf("missing required variables: %s", strings.Join(missing, ", "))
	}

	return nil
}

// applyDefaults applies default values for variables not provided
func applyDefaults(prompt *Prompt, vars TemplateVars) TemplateVars {
	result := make(TemplateVars)

	// Copy provided variables
	for k, v := range vars {
		result[k] = v
	}

	// Apply defaults for missing variables
	for _, variable := range prompt.Variables {
		if _, exists := result[variable.Name]; !exists && variable.Default != "" {
			result[variable.Name] = variable.Default
		}
	}

	return result
}

// ParseTemplateVars parses template variables from command line format
func ParseTemplateVars(vars []string) (TemplateVars, error) {
	result := make(TemplateVars)

	for _, varStr := range vars {
		parts := strings.SplitN(varStr, "=", 2)
		if len(parts) != 2 {
			return nil, fmt.Errorf("invalid template variable format: %s (expected key=value)", varStr)
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		if key == "" {
			return nil, fmt.Errorf("empty variable name in: %s", varStr)
		}

		result[key] = value
	}

	return result, nil
}
