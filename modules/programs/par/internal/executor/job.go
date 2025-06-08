package executor

import (
	"context"
	"fmt"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

type JobExecutor struct {
	claudeExecutor *ClaudeExecutor
}

func NewJobExecutor() *JobExecutor {
	return &JobExecutor{
		claudeExecutor: NewClaudeExecutor(),
	}
}

func (je *JobExecutor) ExecuteJob(ctx context.Context, job *worktree.Job, useTerm bool) *worktree.JobResult {
	job.Start()
	
	result := &worktree.JobResult{
		JobID:     job.ID,
		Worktree:  job.Worktree.GetDisplayName(),
		StartTime: *job.StartedAt,
	}
	
	// Prepare Claude execution
	execution := &ClaudeExecution{
		JobID:       job.ID,
		Worktree:    job.Worktree,
		Prompt:      job.Prompt,
		Timeout:     job.Timeout,
		UseTerminal: useTerm,
	}
	
	var claudeResult *ClaudeResult
	var err error
	
	// Execute with or without terminal
	if useTerm {
		claudeResult, err = je.claudeExecutor.ExecuteWithTerminal(ctx, execution)
	} else {
		claudeResult, err = je.claudeExecutor.Execute(ctx, execution)
	}
	
	job.Complete()
	result.EndTime = *job.CompletedAt
	result.Duration = job.GetDuration()
	
	if err != nil {
		result.Status = worktree.JobStatusFailed
		result.ErrorMessage = fmt.Sprintf("Execution error: %v", err)
		result.ExitCode = -1
		return result
	}
	
	// Process Claude result
	result.Output = claudeResult.Output
	result.ExitCode = claudeResult.ExitCode
	
	if claudeResult.TimedOut {
		result.Status = worktree.JobStatusTimeout
		result.ErrorMessage = fmt.Sprintf("Job timed out after %s", job.Timeout)
	} else if claudeResult.Error != nil {
		result.Status = worktree.JobStatusFailed
		result.ErrorMessage = claudeResult.ErrorOutput
	} else if claudeResult.ExitCode != 0 {
		result.Status = worktree.JobStatusFailed
		result.ErrorMessage = fmt.Sprintf("Claude Code CLI exited with code %d", claudeResult.ExitCode)
	} else {
		result.Status = worktree.JobStatusCompleted
	}
	
	return result
}

func (je *JobExecutor) ValidateEnvironment() error {
	// Validate that Claude CLI is available
	if err := je.claudeExecutor.ValidateClaudeCLI(); err != nil {
		return fmt.Errorf("Claude Code CLI validation failed: %w", err)
	}
	
	return nil
}

func (je *JobExecutor) GetClaudeExecutor() *ClaudeExecutor {
	return je.claudeExecutor
}

type JobMonitor struct {
	jobs     map[string]*worktree.Job
	results  map[string]*worktree.JobResult
	progress chan JobProgress
}

type JobProgress struct {
	JobID    string
	Status   worktree.JobStatus
	Message  string
	Progress float64 // 0.0 to 1.0
}

func NewJobMonitor() *JobMonitor {
	return &JobMonitor{
		jobs:     make(map[string]*worktree.Job),
		results:  make(map[string]*worktree.JobResult),
		progress: make(chan JobProgress, 100),
	}
}

func (jm *JobMonitor) AddJob(job *worktree.Job) {
	jm.jobs[job.ID] = job
	jm.sendProgress(job.ID, worktree.JobStatusPending, "Job queued", 0.0)
}

func (jm *JobMonitor) StartJob(jobID string) {
	if job, exists := jm.jobs[jobID]; exists {
		job.Start()
		jm.sendProgress(jobID, worktree.JobStatusRunning, "Job started", 0.1)
	}
}

func (jm *JobMonitor) CompleteJob(jobID string, result *worktree.JobResult) {
	if job, exists := jm.jobs[jobID]; exists {
		job.Complete()
		jm.results[jobID] = result
		jm.sendProgress(jobID, result.Status, "Job completed", 1.0)
	}
}

func (jm *JobMonitor) GetProgress() <-chan JobProgress {
	return jm.progress
}

func (jm *JobMonitor) GetResults() map[string]*worktree.JobResult {
	return jm.results
}

func (jm *JobMonitor) GetSummary() *worktree.ExecutionSummary {
	summary := &worktree.ExecutionSummary{
		TotalJobs: len(jm.jobs),
	}
	
	var results []*worktree.JobResult
	var minStart, maxEnd time.Time
	
	for _, result := range jm.results {
		results = append(results, result)
		
		if minStart.IsZero() || result.StartTime.Before(minStart) {
			minStart = result.StartTime
		}
		if maxEnd.IsZero() || result.EndTime.After(maxEnd) {
			maxEnd = result.EndTime
		}
		
		switch result.Status {
		case worktree.JobStatusCompleted:
			summary.Successful++
		case worktree.JobStatusFailed:
			summary.Failed++
		case worktree.JobStatusTimeout:
			summary.Timeout++
		case worktree.JobStatusCancelled:
			summary.Cancelled++
		}
	}
	
	summary.Results = results
	if !minStart.IsZero() && !maxEnd.IsZero() {
		summary.StartTime = minStart
		summary.EndTime = maxEnd
		summary.Duration = maxEnd.Sub(minStart)
	}
	
	return summary
}

func (jm *JobMonitor) sendProgress(jobID string, status worktree.JobStatus, message string, progress float64) {
	select {
	case jm.progress <- JobProgress{
		JobID:    jobID,
		Status:   status,
		Message:  message,
		Progress: progress,
	}:
	default:
		// Channel is full, skip this progress update
	}
}

func (jm *JobMonitor) Close() {
	close(jm.progress)
}