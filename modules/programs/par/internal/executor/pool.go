package executor

import (
	"context"
	"fmt"
	"log/slog"
	"sync"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

// Pool manages parallel execution of jobs
type Pool struct {
	workers     int
	config      *config.Config
	claudeExec  *ClaudeExecutor
	jobQueue    chan *Job
	resultQueue chan *JobResult
	workerWg    sync.WaitGroup
	ctx         context.Context
	cancel      context.CancelFunc
}

// NewPool creates a new execution pool
func NewPool(workers int, config *config.Config) *Pool {
	ctx, cancel := context.WithCancel(context.Background())

	return &Pool{
		workers:     workers,
		config:      config,
		claudeExec:  NewClaudeExecutor(config),
		jobQueue:    make(chan *Job, workers*2), // Buffer for smooth flow
		resultQueue: make(chan *JobResult, workers*2),
		ctx:         ctx,
		cancel:      cancel,
	}
}

// Execute executes a batch of jobs in parallel
func (p *Pool) Execute(jobs []*Job) ([]*JobResult, error) {
	slog.Debug("Starting parallel job execution", "job_count", len(jobs), "worker_count", p.workers)

	if len(jobs) == 0 {
		slog.Debug("No jobs to execute")
		return []*JobResult{}, nil
	}

	// Validate Claude Code CLI first
	slog.Debug("Validating Claude Code CLI")
	if err := p.claudeExec.ValidateClaudeCode(); err != nil {
		slog.Debug("Claude Code CLI validation failed", "error", err)
		return nil, fmt.Errorf("claude code validation failed: %w", err)
	}

	// Start workers
	slog.Debug("Starting worker pool", "worker_count", p.workers)
	p.startWorkers()

	// Send jobs to workers
	go func() {
		defer close(p.jobQueue)
		for _, job := range jobs {
			select {
			case p.jobQueue <- job:
			case <-p.ctx.Done():
				return
			}
		}
	}()

	// Collect results
	results := make([]*JobResult, 0, len(jobs))
	for i := 0; i < len(jobs); i++ {
		select {
		case result := <-p.resultQueue:
			results = append(results, result)
		case <-p.ctx.Done():
			return results, p.ctx.Err()
		}
	}

	// Wait for all workers to complete
	p.workerWg.Wait()

	return results, nil
}

// ExecuteSequential executes jobs sequentially (for testing/debugging)
func (p *Pool) ExecuteSequential(jobs []*Job) ([]*JobResult, error) {
	if len(jobs) == 0 {
		return []*JobResult{}, nil
	}

	// Validate Claude Code CLI first
	if err := p.claudeExec.ValidateClaudeCode(); err != nil {
		return nil, fmt.Errorf("claude code validation failed: %w", err)
	}

	results := make([]*JobResult, 0, len(jobs))

	for _, job := range jobs {
		if err := p.claudeExec.ExecuteJob(p.ctx, job); err != nil {
			// Continue with other jobs even if one fails
			slog.Error("Job execution failed", "job_id", job.ID, "error", err)
		}

		results = append(results, job.ToResult())

		// Check for cancellation
		if p.ctx.Err() != nil {
			break
		}
	}

	return results, nil
}

// Stop stops the execution pool
func (p *Pool) Stop() {
	p.cancel()
	p.workerWg.Wait()
}

// startWorkers starts the worker goroutines
func (p *Pool) startWorkers() {
	for i := 0; i < p.workers; i++ {
		p.workerWg.Add(1)
		go p.worker(i)
	}
}

// worker is the worker goroutine that processes jobs
func (p *Pool) worker(id int) {
	defer p.workerWg.Done()

	for {
		select {
		case job, ok := <-p.jobQueue:
			if !ok {
				return // Channel closed
			}

			// Execute the job
			if err := p.claudeExec.ExecuteJob(p.ctx, job); err != nil {
				// Error is already recorded in the job, no additional action needed
				slog.Debug("Job execution completed with error", "job_id", job.ID, "error", err)
			}

			// Send result
			select {
			case p.resultQueue <- job.ToResult():
			case <-p.ctx.Done():
				return
			}

		case <-p.ctx.Done():
			return
		}
	}
}
