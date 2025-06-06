package executor

import (
	"log/slog"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
	"github.com/google/uuid"
)

// Status represents the execution status of a job
type Status string

const (
	StatusPending Status = "pending"
	StatusRunning Status = "running"
	StatusSuccess Status = "success"
	StatusFailed  Status = "failed"
	StatusTimeout Status = "timeout"
)

// Job represents a single execution job
type Job struct {
	ID        string             `json:"id"`
	Worktree  *worktree.Worktree `json:"worktree"`
	Prompt    string             `json:"prompt"`
	Timeout   time.Duration      `json:"timeout"`
	Status    Status             `json:"status"`
	StartTime time.Time          `json:"start_time"`
	EndTime   time.Time          `json:"end_time"`
	Output    string             `json:"output"`
	Error     string             `json:"error,omitempty"`
	ExitCode  int                `json:"exit_code"`
}

// JobResult represents the result of a job execution
type JobResult struct {
	JobID        string        `json:"job_id"`
	Worktree     string        `json:"worktree"`
	Status       Status        `json:"status"`
	StartTime    time.Time     `json:"start_time"`
	EndTime      time.Time     `json:"end_time"`
	Duration     time.Duration `json:"duration"`
	Output       string        `json:"output"`
	ErrorMessage string        `json:"error_message,omitempty"`
	ExitCode     int           `json:"exit_code"`
}

// NewJob creates a new job instance
func NewJob(worktree *worktree.Worktree, prompt string, timeout time.Duration) *Job {
	jobID := uuid.New().String()
	slog.Debug("Creating new job",
		"job_id", jobID,
		"worktree_name", worktree.Name,
		"worktree_path", worktree.Path,
		"timeout", timeout)

	return &Job{
		ID:       jobID,
		Worktree: worktree,
		Prompt:   prompt,
		Timeout:  timeout,
		Status:   StatusPending,
	}
}

// Duration returns the job execution duration
func (j *Job) Duration() time.Duration {
	if j.StartTime.IsZero() {
		return 0
	}

	endTime := j.EndTime
	if endTime.IsZero() {
		endTime = time.Now()
	}

	return endTime.Sub(j.StartTime)
}

// ToResult converts a job to a job result
func (j *Job) ToResult() *JobResult {
	return &JobResult{
		JobID:        j.ID,
		Worktree:     j.Worktree.Path,
		Status:       j.Status,
		StartTime:    j.StartTime,
		EndTime:      j.EndTime,
		Duration:     j.Duration(),
		Output:       j.Output,
		ErrorMessage: j.Error,
		ExitCode:     j.ExitCode,
	}
}
