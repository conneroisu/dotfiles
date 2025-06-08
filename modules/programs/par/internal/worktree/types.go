package worktree

import (
	"time"

	"github.com/google/uuid"
)

type Worktree struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Path        string `json:"path"`
	Branch      string `json:"branch"`
	RemoteURL   string `json:"remote_url"`
	LastCommit  string `json:"last_commit"`
	IsDirty     bool   `json:"is_dirty"`
	IsValid     bool   `json:"is_valid"`
	ProjectName string `json:"project_name"`
}

type WorktreeManager struct {
	searchPaths     []string
	excludePatterns []string
}

type ValidationResult struct {
	IsValid bool     `json:"is_valid"`
	Errors  []string `json:"errors"`
	Warnings []string `json:"warnings"`
}

type Job struct {
	ID          string                 `json:"id"`
	Worktree    *Worktree             `json:"worktree"`
	Prompt      string                `json:"prompt"`
	PromptName  string                `json:"prompt_name"`
	Timeout     time.Duration         `json:"timeout"`
	Variables   map[string]interface{} `json:"variables"`
	CreatedAt   time.Time             `json:"created_at"`
	StartedAt   *time.Time            `json:"started_at,omitempty"`
	CompletedAt *time.Time            `json:"completed_at,omitempty"`
}

type JobStatus string

const (
	JobStatusPending   JobStatus = "pending"
	JobStatusRunning   JobStatus = "running"
	JobStatusCompleted JobStatus = "completed"
	JobStatusFailed    JobStatus = "failed"
	JobStatusTimeout   JobStatus = "timeout"
	JobStatusCancelled JobStatus = "cancelled"
)

type JobResult struct {
	JobID        string        `json:"job_id"`
	Worktree     string        `json:"worktree"`
	Status       JobStatus     `json:"status"`
	StartTime    time.Time     `json:"start_time"`
	EndTime      time.Time     `json:"end_time"`
	Duration     time.Duration `json:"duration"`
	Output       string        `json:"output"`
	ErrorMessage string        `json:"error_message,omitempty"`
	ExitCode     int           `json:"exit_code"`
}

type ExecutionPlan struct {
	ID          string    `json:"id"`
	PromptName  string    `json:"prompt_name"`
	Jobs        []*Job    `json:"jobs"`
	TotalJobs   int       `json:"total_jobs"`
	MaxWorkers  int       `json:"max_workers"`
	Timeout     time.Duration `json:"timeout"`
	CreatedAt   time.Time `json:"created_at"`
	DryRun      bool      `json:"dry_run"`
	UseTerm     bool      `json:"use_term"`
}

type ExecutionSummary struct {
	PlanID       string         `json:"plan_id"`
	TotalJobs    int           `json:"total_jobs"`
	Successful   int           `json:"successful"`
	Failed       int           `json:"failed"`
	Timeout      int           `json:"timeout"`
	Cancelled    int           `json:"cancelled"`
	Duration     time.Duration `json:"duration"`
	Results      []*JobResult  `json:"results"`
	StartTime    time.Time     `json:"start_time"`
	EndTime      time.Time     `json:"end_time"`
}

func NewJob(worktree *Worktree, prompt, promptName string, timeout time.Duration, variables map[string]interface{}) *Job {
	return &Job{
		ID:         uuid.New().String(),
		Worktree:   worktree,
		Prompt:     prompt,
		PromptName: promptName,
		Timeout:    timeout,
		Variables:  variables,
		CreatedAt:  time.Now(),
	}
}

func NewExecutionPlan(promptName string, jobs []*Job, maxWorkers int, timeout time.Duration, dryRun, useTerm bool) *ExecutionPlan {
	return &ExecutionPlan{
		ID:         uuid.New().String(),
		PromptName: promptName,
		Jobs:       jobs,
		TotalJobs:  len(jobs),
		MaxWorkers: maxWorkers,
		Timeout:    timeout,
		CreatedAt:  time.Now(),
		DryRun:     dryRun,
		UseTerm:    useTerm,
	}
}

func (j *Job) Start() {
	now := time.Now()
	j.StartedAt = &now
}

func (j *Job) Complete() {
	now := time.Now()
	j.CompletedAt = &now
}

func (j *Job) GetDuration() time.Duration {
	if j.StartedAt == nil {
		return 0
	}
	if j.CompletedAt == nil {
		return time.Since(*j.StartedAt)
	}
	return j.CompletedAt.Sub(*j.StartedAt)
}

func (w *Worktree) GetDisplayName() string {
	if w.ProjectName != "" {
		return w.ProjectName
	}
	return w.Name
}