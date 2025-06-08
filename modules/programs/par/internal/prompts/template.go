package prompts

import (
	"bytes"
	"fmt"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

type TemplateProcessor struct {
	funcMap template.FuncMap
}

type TemplateContext struct {
	ProjectName     string                 `json:"project_name"`
	TaskName        string                 `json:"task_name"`
	Description     string                 `json:"description"`
	BranchName      string                 `json:"branch_name"`
	WorktreePath    string                 `json:"worktree_path"`
	Instructions    string                 `json:"instructions"`
	ExpectedOutcome string                 `json:"expected_outcome"`
	Variables       map[string]interface{} `json:"variables"`
}

func NewTemplateProcessor() *TemplateProcessor {
	funcMap := template.FuncMap{
		"upper":   strings.ToUpper,
		"lower":   strings.ToLower,
		"title":   strings.Title,
		"default": defaultValue,
		"join":    strings.Join,
		"replace": strings.ReplaceAll,
		"contains": strings.Contains,
		"basename": filepath.Base,
		"dirname":  filepath.Dir,
	}
	
	return &TemplateProcessor{
		funcMap: funcMap,
	}
}

func (tp *TemplateProcessor) Process(prompt *Prompt, wt *worktree.Worktree, variables map[string]interface{}) (string, error) {
	if !prompt.IsTemplate {
		return prompt.Content, nil
	}
	
	context := tp.createContext(prompt, wt, variables)
	
	tmpl, err := template.New("prompt").Funcs(tp.funcMap).Parse(prompt.Content)
	if err != nil {
		return "", fmt.Errorf("failed to parse template: %w", err)
	}
	
	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, context); err != nil {
		return "", fmt.Errorf("failed to execute template: %w", err)
	}
	
	return buf.String(), nil
}

func (tp *TemplateProcessor) ValidateTemplate(content string) error {
	_, err := template.New("validation").Funcs(tp.funcMap).Parse(content)
	if err != nil {
		return fmt.Errorf("invalid template syntax: %w", err)
	}
	return nil
}

func (tp *TemplateProcessor) createContext(prompt *Prompt, wt *worktree.Worktree, variables map[string]interface{}) *TemplateContext {
	context := &TemplateContext{
		ProjectName:  wt.GetDisplayName(),
		TaskName:     prompt.Name,
		Description:  prompt.Description,
		BranchName:   wt.Branch,
		WorktreePath: wt.Path,
		Variables:    make(map[string]interface{}),
	}
	
	// Merge prompt variables with provided variables
	for k, v := range prompt.Variables {
		context.Variables[k] = v
	}
	for k, v := range variables {
		context.Variables[k] = v
	}
	
	// Extract specific variables if they exist
	if val, ok := context.Variables["Instructions"]; ok {
		if str, ok := val.(string); ok {
			context.Instructions = str
		}
	}
	if val, ok := context.Variables["ExpectedOutcome"]; ok {
		if str, ok := val.(string); ok {
			context.ExpectedOutcome = str
		}
	}
	if val, ok := context.Variables["TaskName"]; ok {
		if str, ok := val.(string); ok {
			context.TaskName = str
		}
	}
	if val, ok := context.Variables["Description"]; ok {
		if str, ok := val.(string); ok {
			context.Description = str
		}
	}
	
	return context
}

func (tp *TemplateProcessor) GetAvailableFunctions() map[string]string {
	return map[string]string{
		"upper":    "Convert string to uppercase",
		"lower":    "Convert string to lowercase", 
		"title":    "Convert string to title case",
		"default":  "Provide default value if variable is empty",
		"join":     "Join array elements with separator",
		"replace":  "Replace all occurrences of substring",
		"contains": "Check if string contains substring",
		"basename": "Get base name of file path",
		"dirname":  "Get directory name of file path",
	}
}

func (tp *TemplateProcessor) RenderExample() string {
	return `# {{.ProjectName}} - {{.TaskName}}

## Task Description
{{.Description}}

## Context
Project: {{.ProjectName}}
Branch: {{.BranchName}}
Worktree: {{.WorktreePath}}

## Instructions
{{default "No specific instructions provided" .Instructions}}

## Expected Outcome
{{default "Successful completion of the task" .ExpectedOutcome}}

## Additional Variables
{{range $key, $value := .Variables}}
- {{$key}}: {{$value}}
{{end}}`
}

func defaultValue(defaultVal interface{}, value interface{}) interface{} {
	if value == nil || value == "" {
		return defaultVal
	}
	return value
}