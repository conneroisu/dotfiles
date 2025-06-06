package prompts

import (
	"bytes"
	"fmt"
	"log/slog"
	"strings"
	"text/template"
)

// TemplateVars represents template variable substitutions
type TemplateVars map[string]string

// ProcessTemplate processes a prompt template with provided variables
func ProcessTemplate(prompt *Prompt, vars TemplateVars) (string, error) {
	slog.Debug("Processing template", "prompt_name", prompt.Name, "is_template", prompt.Template, "variables_provided", len(vars))
	
	if !prompt.Template {
		slog.Debug("Prompt is not a template, returning content as-is", "prompt_name", prompt.Name)
		return prompt.Content, nil
	}
	
	// Log provided variables (without values for security)
	var varNames []string
	for name := range vars {
		varNames = append(varNames, name)
	}
	slog.Debug("Template variables provided", "prompt_name", prompt.Name, "variable_names", varNames)
	
	// Validate required variables
	if err := validateVariables(prompt, vars); err != nil {
		slog.Debug("Template variable validation failed", "prompt_name", prompt.Name, "error", err)
		return "", err
	}
	
	// Apply defaults for missing variables
	finalVars := applyDefaults(prompt, vars)
	slog.Debug("Applied template defaults", "prompt_name", prompt.Name, "final_var_count", len(finalVars))
	
	// Process the template
	slog.Debug("Parsing template", "prompt_name", prompt.Name, "content_length", len(prompt.Content))
	tmpl, err := template.New(prompt.Name).Parse(prompt.Content)
	if err != nil {
		slog.Debug("Failed to parse template", "prompt_name", prompt.Name, "error", err)
		return "", fmt.Errorf("failed to parse template: %w", err)
	}
	
	var buf bytes.Buffer
	slog.Debug("Executing template", "prompt_name", prompt.Name)
	if err := tmpl.Execute(&buf, finalVars); err != nil {
		slog.Debug("Failed to execute template", "prompt_name", prompt.Name, "error", err)
		return "", fmt.Errorf("failed to execute template: %w", err)
	}
	
	result := buf.String()
	slog.Debug("Template processing completed", "prompt_name", prompt.Name, "output_length", len(result))
	return result, nil
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