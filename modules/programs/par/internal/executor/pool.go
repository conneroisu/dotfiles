package executor

import (
	"fmt"
	"sync"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

// Pool manages parallel job execution
type Pool struct {
	config   *config.Config
	workers  int
	claude   *ClaudeExecutor
	terminal *TerminalManager
}

// NewPool creates a new execution pool
func NewPool(cfg *config.Config) (*Pool, error) {
	claude, err := NewClaudeExecutor(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize claude executor: %w", err)
	}

	terminal, err := NewTerminalManager(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize terminal manager: %w", err)
	}

	return &Pool{
		config:   cfg,
		workers:  cfg.Defaults.Jobs,
		claude:   claude,
		terminal: terminal,
	}, nil
}

// Execute executes jobs across multiple worktrees
func (p *Pool) Execute(prompt *prompts.Prompt, worktrees []*worktree.Worktree, opts *ExecuteOptions) ([]*JobResult, error) {
	// Create jobs
	jobs := make([]*Job, len(worktrees))
	for i, wt := range worktrees {
		jobs[i] = NewJob(wt, prompt, opts)
	}

	// Create channels for job management
	jobChan := make(chan *Job, len(jobs))
	resultChan := make(chan *JobResult, len(jobs))

	// Start workers
	var wg sync.WaitGroup
	for i := 0; i < p.workers; i++ {
		wg.Add(1)
		go p.worker(jobChan, resultChan, &wg)
	}

	// Send jobs to workers
	for _, job := range jobs {
		jobChan <- job
	}
	close(jobChan)

	// Wait for all workers to finish
	go func() {
		wg.Wait()
		close(resultChan)
	}()

	// Collect results
	var results []*JobResult
	for result := range resultChan {
		results = append(results, result)
	}

	return results, nil
}

// worker processes jobs from the job channel
func (p *Pool) worker(jobChan <-chan *Job, resultChan chan<- *JobResult, wg *sync.WaitGroup) {
	defer wg.Done()

	for job := range jobChan {
		result := p.executeJob(job)
		resultChan <- result
	}
}

// executeJob executes a single job
func (p *Pool) executeJob(job *Job) *JobResult {
	job.Start()

	// Process template if needed
	processor := prompts.NewProcessor()
	processedContent, err := processor.ProcessPrompt(job.Prompt, job.TemplateVars)
	if err != nil {
		job.Fail(fmt.Errorf("failed to process prompt template: %w", err))
		return job.Result
	}

	// Execute based on options
	var result *JobResult
	if job.Options.UseTerm {
		result, err = p.terminal.Execute(job, processedContent)
	} else {
		result, err = p.claude.Execute(job, processedContent)
	}

	if err != nil {
		job.Fail(err)
		return job.Result
	}

	job.Complete(result)
	return result
}

// Shutdown gracefully shuts down the pool
func (p *Pool) Shutdown() error {
	// Cancel any running jobs
	// Clean up resources
	return nil
}