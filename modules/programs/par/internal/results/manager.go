package results

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"text/tabwriter"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

type Manager struct {
	outputDir string
}

type ExecutionReport struct {
	ID           string                      `json:"id"`
	PromptName   string                      `json:"prompt_name"`
	StartTime    time.Time                   `json:"start_time"`
	EndTime      time.Time                   `json:"end_time"`
	Duration     time.Duration               `json:"duration"`
	Summary      *worktree.ExecutionSummary  `json:"summary"`
	Results      []*worktree.JobResult       `json:"results"`
	Config       *ExecutionConfig            `json:"config"`
}

type ExecutionConfig struct {
	MaxWorkers int           `json:"max_workers"`
	Timeout    time.Duration `json:"timeout"`
	DryRun     bool          `json:"dry_run"`
	UseTerm    bool          `json:"use_term"`
}

func NewManager() (*Manager, error) {
	cfg := config.Get()
	outputDir := config.ExpandPath(cfg.Defaults.OutputDir)
	
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create output directory: %w", err)
	}
	
	return &Manager{
		outputDir: outputDir,
	}, nil
}

func (m *Manager) SaveReport(report *ExecutionReport) error {
	filename := fmt.Sprintf("execution-%s-%s.json", 
		report.PromptName, 
		report.StartTime.Format("20060102-150405"))
	
	filepath := filepath.Join(m.outputDir, filename)
	
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %w", err)
	}
	
	if err := os.WriteFile(filepath, data, 0644); err != nil {
		return fmt.Errorf("failed to write report: %w", err)
	}
	
	return nil
}

func (m *Manager) LoadReport(filename string) (*ExecutionReport, error) {
	filepath := filepath.Join(m.outputDir, filename)
	
	data, err := os.ReadFile(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to read report: %w", err)
	}
	
	var report ExecutionReport
	if err := json.Unmarshal(data, &report); err != nil {
		return nil, fmt.Errorf("failed to unmarshal report: %w", err)
	}
	
	return &report, nil
}

func (m *Manager) ListReports() ([]string, error) {
	files, err := filepath.Glob(filepath.Join(m.outputDir, "execution-*.json"))
	if err != nil {
		return nil, fmt.Errorf("failed to glob reports: %w", err)
	}
	
	var reports []string
	for _, file := range files {
		reports = append(reports, filepath.Base(file))
	}
	
	return reports, nil
}

func (m *Manager) CreateReport(plan *worktree.ExecutionPlan, summary *worktree.ExecutionSummary, results []*worktree.JobResult) *ExecutionReport {
	return &ExecutionReport{
		ID:         plan.ID,
		PromptName: plan.PromptName,
		StartTime:  summary.StartTime,
		EndTime:    summary.EndTime,
		Duration:   summary.Duration,
		Summary:    summary,
		Results:    results,
		Config: &ExecutionConfig{
			MaxWorkers: plan.MaxWorkers,
			Timeout:    plan.Timeout,
			DryRun:     plan.DryRun,
			UseTerm:    plan.UseTerm,
		},
	}
}

func (m *Manager) PrintSummary(summary *worktree.ExecutionSummary) {
	fmt.Println("\nPar Execution Summary")
	fmt.Println("=====================")
	fmt.Printf("Total Jobs: %d\n", summary.TotalJobs)
	fmt.Printf("Successful: %d\n", summary.Successful)
	fmt.Printf("Failed: %d\n", summary.Failed)
	
	if summary.Timeout > 0 {
		fmt.Printf("Timeout: %d\n", summary.Timeout)
	}
	if summary.Cancelled > 0 {
		fmt.Printf("Cancelled: %d\n", summary.Cancelled)
	}
	
	fmt.Printf("Total Duration: %s\n", formatDuration(summary.Duration))
	
	if summary.Failed > 0 || summary.Timeout > 0 || summary.Cancelled > 0 {
		fmt.Println("\nFailed/Problematic Jobs:")
		for _, result := range summary.Results {
			if result.Status != worktree.JobStatusCompleted {
				status := string(result.Status)
				if result.Status == worktree.JobStatusFailed && result.ErrorMessage != "" {
					status = fmt.Sprintf("%s: %s", status, result.ErrorMessage)
				}
				fmt.Printf("- %s: %s\n", result.Worktree, status)
			}
		}
	}
}

func (m *Manager) PrintDetailedResults(results []*worktree.JobResult) {
	if len(results) == 0 {
		fmt.Println("No results to display.")
		return
	}
	
	fmt.Println("\nDetailed Results")
	fmt.Println("================")
	
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "WORKTREE\tSTATUS\tDURATION\tERROR")
	
	for _, result := range results {
		status := string(result.Status)
		duration := formatDuration(result.Duration)
		errorMsg := result.ErrorMessage
		if errorMsg == "" {
			errorMsg = "-"
		} else if len(errorMsg) > 50 {
			errorMsg = errorMsg[:47] + "..."
		}
		
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n",
			result.Worktree, status, duration, errorMsg)
	}
	
	w.Flush()
}

func (m *Manager) PrintJSONSummary(summary *worktree.ExecutionSummary) error {
	data, err := json.MarshalIndent(summary, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal summary: %w", err)
	}
	
	fmt.Println(string(data))
	return nil
}

func (m *Manager) SaveJobOutput(jobID, worktreeName, output string) error {
	// Create a subdirectory for job outputs
	jobDir := filepath.Join(m.outputDir, "jobs")
	if err := os.MkdirAll(jobDir, 0755); err != nil {
		return fmt.Errorf("failed to create job output directory: %w", err)
	}
	
	filename := fmt.Sprintf("%s-%s.log", jobID, worktreeName)
	filepath := filepath.Join(jobDir, filename)
	
	if err := os.WriteFile(filepath, []byte(output), 0644); err != nil {
		return fmt.Errorf("failed to write job output: %w", err)
	}
	
	return nil
}

func (m *Manager) SaveJobError(jobID, worktreeName, errorMsg string) error {
	jobDir := filepath.Join(m.outputDir, "jobs")
	if err := os.MkdirAll(jobDir, 0755); err != nil {
		return fmt.Errorf("failed to create job output directory: %w", err)
	}
	
	filename := fmt.Sprintf("%s-%s.error", jobID, worktreeName)
	filepath := filepath.Join(jobDir, filename)
	
	if err := os.WriteFile(filepath, []byte(errorMsg), 0644); err != nil {
		return fmt.Errorf("failed to write job error: %w", err)
	}
	
	return nil
}

func (m *Manager) GetOutputDir() string {
	return m.outputDir
}

func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%.1fs", d.Seconds())
	} else if d < time.Hour {
		return fmt.Sprintf("%.1fm", d.Minutes())
	} else {
		return fmt.Sprintf("%.1fh", d.Hours())
	}
}