// Package executor handles parallel job execution
package executor

import (
	"context"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
	"github.com/google/uuid"
)

// Job represents a single execution job
type Job struct {
	ID           string                `json:"id"`
	Worktree     *worktree.Worktree    `json:"worktree"`
	Prompt       *prompts.Prompt       `json:"prompt"`
	TemplateVars prompts.TemplateVars  `json:"template_vars"`
	Options      *ExecuteOptions       `json:"options"`
	Context      context.Context       `json:"-"`
	Cancel       context.CancelFunc    `json:"-"`
	StartTime    time.Time             `json:"start_time"`
	EndTime      time.Time             `json:"end_time"`
	Status       JobStatus             `json:"status"`
	Result       *JobResult            `json:"result,omitempty"`
}

// JobStatus represents the status of a job
type JobStatus string

const (
	JobStatusPending   JobStatus = "pending"
	JobStatusRunning   JobStatus = "running"
	JobStatusCompleted JobStatus = "completed"
	JobStatusFailed    JobStatus = "failed"
	JobStatusCancelled JobStatus = "cancelled"
	JobStatusTimeout   JobStatus = "timeout"
)

// JobResult contains the result of job execution
type JobResult struct {
	JobID        string        `json:"job_id"`
	Worktree     string        `json:"worktree"`
	Status       string        `json:"status"`
	StartTime    time.Time     `json:"start_time"`
	EndTime      time.Time     `json:"end_time"`
	Duration     time.Duration `json:"duration"`
	Output       string        `json:"output"`
	ErrorMessage string        `json:"error_message,omitempty"`
	ExitCode     int           `json:"exit_code"`
	CommitHash   string        `json:"commit_hash,omitempty"`
	FilesChanged []string      `json:"files_changed,omitempty"`
}

// ExecuteOptions contains options for job execution
type ExecuteOptions struct {
	Jobs           int           `json:"jobs"`
	Timeout        time.Duration `json:"timeout"`
	UseTerm        bool          `json:"use_term"`
	TerminalOutput bool          `json:"terminal_output"`
	BaseBranch     string        `json:"base_branch"`
	Plan           bool          `json:"plan"`
	Verbose        bool          `json:"verbose"`
	DryRun         bool          `json:"dry_run"`
}

// NewJob creates a new job
func NewJob(wt *worktree.Worktree, prompt *prompts.Prompt, opts *ExecuteOptions) *Job {
	ctx, cancel := context.WithTimeout(context.Background(), opts.Timeout)
	
	// Create template variables
	templateVars := prompts.TemplateVars{
		ProjectName:    wt.Name,
		BranchName:     wt.Branch,
		WorktreePath:   wt.Path,
		TaskName:       prompt.Name,
		Description:    prompt.Description,
		Instructions:   prompt.Content,
		ExpectedOutcome: "Successful execution of prompt across worktree",
		Custom:         make(map[string]interface{}),
	}

	return &Job{
		ID:           uuid.New().String(),
		Worktree:     wt,
		Prompt:       prompt,
		TemplateVars: templateVars,
		Options:      opts,
		Context:      ctx,
		Cancel:       cancel,
		Status:       JobStatusPending,
	}
}

// Start marks the job as started
func (j *Job) Start() {
	j.Status = JobStatusRunning
	j.StartTime = time.Now()
}

// Complete marks the job as completed with result
func (j *Job) Complete(result *JobResult) {
	j.Status = JobStatusCompleted
	j.EndTime = time.Now()
	j.Result = result
	j.Cancel() // Clean up context
}

// Fail marks the job as failed
func (j *Job) Fail(err error) {
	j.Status = JobStatusFailed
	j.EndTime = time.Now()
	j.Result = &JobResult{
		JobID:        j.ID,
		Worktree:     j.Worktree.Name,
		Status:       "failed",
		StartTime:    j.StartTime,
		EndTime:      j.EndTime,
		Duration:     j.EndTime.Sub(j.StartTime),
		ErrorMessage: err.Error(),
		ExitCode:     1,
	}
	j.Cancel() // Clean up context
}

// Cancel cancels the job
func (j *Job) Cancel() {
	if j.Status == JobStatusRunning {
		j.Status = JobStatusCancelled
		j.EndTime = time.Now()
	}
	j.Cancel()
}

// IsFinished returns true if the job has finished (completed, failed, cancelled, or timed out)
func (j *Job) IsFinished() bool {
	return j.Status == JobStatusCompleted || j.Status == JobStatusFailed || j.Status == JobStatusCancelled || j.Status == JobStatusTimeout
}

// GetDuration returns the duration of the job
func (j *Job) GetDuration() time.Duration {
	if j.StartTime.IsZero() {
		return 0
	}
	if j.EndTime.IsZero() {
		return time.Since(j.StartTime)
	}
	return j.EndTime.Sub(j.StartTime)
}