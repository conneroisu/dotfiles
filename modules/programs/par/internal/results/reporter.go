package results

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/executor"
)

// Reporter generates reports from execution summaries
type Reporter struct{}

// NewReporter creates a new reporter
func NewReporter() *Reporter {
	return &Reporter{}
}

// GenerateConsoleReport generates a human-readable console report
func (r *Reporter) GenerateConsoleReport(summary *Summary) string {
	var sb strings.Builder
	
	sb.WriteString("Par Execution Summary\n")
	sb.WriteString("=====================\n")
	sb.WriteString(fmt.Sprintf("Total Jobs: %d\n", summary.TotalJobs))
	sb.WriteString(fmt.Sprintf("Successful: %d\n", summary.SuccessfulJobs))
	sb.WriteString(fmt.Sprintf("Failed: %d\n", summary.FailedJobs))
	sb.WriteString(fmt.Sprintf("Timeout: %d\n", summary.TimeoutJobs))
	sb.WriteString(fmt.Sprintf("Success Rate: %.1f%%\n", summary.GetSuccessRate()))
	sb.WriteString(fmt.Sprintf("Total Duration: %s\n", r.formatDuration(summary.TotalDuration)))
	sb.WriteString(fmt.Sprintf("Average Job Duration: %s\n", r.formatDuration(summary.GetAverageDuration())))
	
	if summary.HasFailures() {
		sb.WriteString("\nFailed Jobs:\n")
		for _, result := range summary.FailedResults {
			sb.WriteString(fmt.Sprintf("- %s: %s", 
				result.Worktree, 
				r.getFailureReason(result)))
			if result.ErrorMessage != "" {
				sb.WriteString(fmt.Sprintf(" (%s)", result.ErrorMessage))
			}
			sb.WriteString("\n")
		}
	}
	
	if len(summary.Results) > 0 {
		fastest := summary.GetFastestJob()
		slowest := summary.GetSlowestJob()
		
		sb.WriteString("\nPerformance:\n")
		sb.WriteString(fmt.Sprintf("Fastest: %s (%s)\n", 
			fastest.Worktree, 
			r.formatDuration(fastest.Duration)))
		sb.WriteString(fmt.Sprintf("Slowest: %s (%s)\n", 
			slowest.Worktree, 
			r.formatDuration(slowest.Duration)))
	}
	
	return sb.String()
}

// GenerateJSONReport generates a JSON report
func (r *Reporter) GenerateJSONReport(summary *Summary) (string, error) {
	data, err := json.MarshalIndent(summary, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to marshal JSON report: %w", err)
	}
	
	return string(data), nil
}

// GenerateDetailedReport generates a detailed report with job outputs
func (r *Reporter) GenerateDetailedReport(summary *Summary) string {
	var sb strings.Builder
	
	// Start with console report
	sb.WriteString(r.GenerateConsoleReport(summary))
	
	if len(summary.Results) > 0 {
		sb.WriteString("\nDetailed Results:\n")
		sb.WriteString("=================\n")
		
		for _, result := range summary.Results {
			sb.WriteString(fmt.Sprintf("\nJob: %s\n", result.JobID))
			sb.WriteString(fmt.Sprintf("Worktree: %s\n", result.Worktree))
			sb.WriteString(fmt.Sprintf("Status: %s\n", result.Status))
			sb.WriteString(fmt.Sprintf("Duration: %s\n", r.formatDuration(result.Duration)))
			sb.WriteString(fmt.Sprintf("Start Time: %s\n", result.StartTime.Format(time.RFC3339)))
			sb.WriteString(fmt.Sprintf("End Time: %s\n", result.EndTime.Format(time.RFC3339)))
			
			if result.ErrorMessage != "" {
				sb.WriteString(fmt.Sprintf("Error: %s\n", result.ErrorMessage))
			}
			
			if result.Output != "" {
				sb.WriteString("Output:\n")
				sb.WriteString(r.indentText(result.Output, "  "))
				sb.WriteString("\n")
			}
			
			sb.WriteString(strings.Repeat("-", 50) + "\n")
		}
	}
	
	return sb.String()
}

// GenerateCSVReport generates a CSV report for data analysis
func (r *Reporter) GenerateCSVReport(summary *Summary) string {
	var sb strings.Builder
	
	// CSV header
	sb.WriteString("job_id,worktree,status,duration_ms,start_time,end_time,error_message\n")
	
	for _, result := range summary.Results {
		sb.WriteString(fmt.Sprintf("%s,%s,%s,%d,%s,%s,%s\n",
			result.JobID,
			r.escapeCsvField(result.Worktree),
			result.Status,
			result.Duration.Milliseconds(),
			result.StartTime.Format(time.RFC3339),
			result.EndTime.Format(time.RFC3339),
			r.escapeCsvField(result.ErrorMessage)))
	}
	
	return sb.String()
}

// formatDuration formats a duration in a human-readable way
func (r *Reporter) formatDuration(d time.Duration) string {
	if d < time.Second {
		return fmt.Sprintf("%dms", d.Milliseconds())
	} else if d < time.Minute {
		return fmt.Sprintf("%.1fs", d.Seconds())
	} else {
		return fmt.Sprintf("%.1fm", d.Minutes())
	}
}

// getFailureReason returns a human-readable failure reason
func (r *Reporter) getFailureReason(result *executor.JobResult) string {
	switch result.Status {
	case executor.StatusTimeout:
		return "timeout"
	case executor.StatusFailed:
		if result.ExitCode != 0 {
			return fmt.Sprintf("exit code %d", result.ExitCode)
		}
		return "execution failed"
	default:
		return "unknown failure"
	}
}

// indentText indents each line of text with the given prefix
func (r *Reporter) indentText(text, indent string) string {
	lines := strings.Split(text, "\n")
	for i, line := range lines {
		lines[i] = indent + line
	}
	return strings.Join(lines, "\n")
}

// escapeCsvField escapes a field for CSV output
func (r *Reporter) escapeCsvField(field string) string {
	if strings.Contains(field, ",") || strings.Contains(field, "\"") || strings.Contains(field, "\n") {
		field = strings.ReplaceAll(field, "\"", "\"\"")
		field = "\"" + field + "\""
	}
	return field
}