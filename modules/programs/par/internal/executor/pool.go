package executor

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

type WorkerPool struct {
	numWorkers   int
	jobs         chan *worktree.Job
	results      chan *worktree.JobResult
	done         chan struct{}
	ctx          context.Context
	cancel       context.CancelFunc
	wg           sync.WaitGroup
	executor     *JobExecutor
	monitor      *JobMonitor
	useTerm      bool
}

type PoolOptions struct {
	NumWorkers int
	UseTerm    bool
	Timeout    time.Duration
}

func NewWorkerPool(options PoolOptions) *WorkerPool {
	ctx, cancel := context.WithCancel(context.Background())
	
	return &WorkerPool{
		numWorkers: options.NumWorkers,
		jobs:       make(chan *worktree.Job, options.NumWorkers*2),
		results:    make(chan *worktree.JobResult, options.NumWorkers*2),
		done:       make(chan struct{}),
		ctx:        ctx,
		cancel:     cancel,
		executor:   NewJobExecutor(),
		monitor:    NewJobMonitor(),
		useTerm:    options.UseTerm,
	}
}

func (wp *WorkerPool) Start() {
	for i := 0; i < wp.numWorkers; i++ {
		wp.wg.Add(1)
		go wp.worker(i)
	}
	
	// Start result collector
	go wp.resultCollector()
}

func (wp *WorkerPool) worker(id int) {
	defer wp.wg.Done()
	
	for {
		select {
		case job := <-wp.jobs:
			if job == nil {
				return
			}
			
			wp.monitor.StartJob(job.ID)
			
			// Execute the job
			result := wp.executor.ExecuteJob(wp.ctx, job, wp.useTerm)
			
			wp.monitor.CompleteJob(job.ID, result)
			
			// Send result
			select {
			case wp.results <- result:
			case <-wp.ctx.Done():
				return
			}
			
		case <-wp.ctx.Done():
			return
		}
	}
}

func (wp *WorkerPool) resultCollector() {
	for {
		select {
		case result := <-wp.results:
			if result == nil {
				return
			}
			// Results are automatically collected by the monitor
			
		case <-wp.ctx.Done():
			return
		}
	}
}

func (wp *WorkerPool) SubmitJob(job *worktree.Job) error {
	wp.monitor.AddJob(job)
	
	select {
	case wp.jobs <- job:
		return nil
	case <-wp.ctx.Done():
		return fmt.Errorf("worker pool is shutting down")
	default:
		return fmt.Errorf("job queue is full")
	}
}

func (wp *WorkerPool) SubmitJobs(jobs []*worktree.Job) error {
	for _, job := range jobs {
		if err := wp.SubmitJob(job); err != nil {
			return fmt.Errorf("failed to submit job %s: %w", job.ID, err)
		}
	}
	return nil
}

func (wp *WorkerPool) Wait() *worktree.ExecutionSummary {
	// Close the jobs channel to signal no more jobs
	close(wp.jobs)
	
	// Wait for all workers to finish
	wp.wg.Wait()
	
	// Close results channel
	close(wp.results)
	
	// Get final summary
	summary := wp.monitor.GetSummary()
	
	return summary
}

func (wp *WorkerPool) Stop() {
	wp.cancel()
	wp.Wait()
}

func (wp *WorkerPool) GetProgress() <-chan JobProgress {
	return wp.monitor.GetProgress()
}

func (wp *WorkerPool) GetResults() map[string]*worktree.JobResult {
	return wp.monitor.GetResults()
}

func (wp *WorkerPool) ValidateEnvironment() error {
	return wp.executor.ValidateEnvironment()
}

type ExecutionManager struct {
	pool    *WorkerPool
	options PoolOptions
}

func NewExecutionManager(options PoolOptions) *ExecutionManager {
	return &ExecutionManager{
		options: options,
	}
}

func (em *ExecutionManager) Execute(plan *worktree.ExecutionPlan) (*worktree.ExecutionSummary, error) {
	// Create worker pool
	em.pool = NewWorkerPool(em.options)
	
	// Validate environment
	if err := em.pool.ValidateEnvironment(); err != nil {
		return nil, fmt.Errorf("environment validation failed: %w", err)
	}
	
	// Start the pool
	em.pool.Start()
	
	fmt.Printf("Starting execution with %d workers...\n", em.options.NumWorkers)
	fmt.Printf("Jobs to execute: %d\n", len(plan.Jobs))
	fmt.Printf("Terminal mode: %t\n", em.options.UseTerm)
	
	if plan.DryRun {
		return em.executeDryRun(plan)
	}
	
	// Start progress monitoring
	go em.monitorProgress()
	
	// Submit all jobs
	if err := em.pool.SubmitJobs(plan.Jobs); err != nil {
		em.pool.Stop()
		return nil, fmt.Errorf("failed to submit jobs: %w", err)
	}
	
	// Wait for completion
	summary := em.pool.Wait()
	summary.PlanID = plan.ID
	
	return summary, nil
}

func (em *ExecutionManager) executeDryRun(plan *worktree.ExecutionPlan) (*worktree.ExecutionSummary, error) {
	fmt.Println("\nDRY RUN - No actual execution")
	fmt.Println("==============================")
	
	for i, job := range plan.Jobs {
		fmt.Printf("[%d/%d] Would execute on %s (%s)\n", 
			i+1, len(plan.Jobs), 
			job.Worktree.GetDisplayName(), 
			job.Worktree.Branch)
		fmt.Printf("  Path: %s\n", job.Worktree.Path)
		fmt.Printf("  Prompt: %s\n", job.PromptName)
		if len(job.Prompt) > 100 {
			fmt.Printf("  Content: %s...\n", job.Prompt[:97])
		} else {
			fmt.Printf("  Content: %s\n", job.Prompt)
		}
		fmt.Println()
	}
	
	// Create a dummy summary for dry run
	summary := &worktree.ExecutionSummary{
		PlanID:      plan.ID,
		TotalJobs:   len(plan.Jobs),
		Successful:  len(plan.Jobs), // All would succeed in dry run
		Failed:      0,
		Timeout:     0,
		Cancelled:   0,
		Duration:    0,
		Results:     []*worktree.JobResult{},
		StartTime:   time.Now(),
		EndTime:     time.Now(),
	}
	
	return summary, nil
}

func (em *ExecutionManager) monitorProgress() {
	progress := em.pool.GetProgress()
	
	for update := range progress {
		switch update.Status {
		case worktree.JobStatusRunning:
			fmt.Printf("▶ Started: %s\n", update.JobID[:8])
		case worktree.JobStatusCompleted:
			fmt.Printf("✓ Completed: %s\n", update.JobID[:8])
		case worktree.JobStatusFailed:
			fmt.Printf("✗ Failed: %s\n", update.JobID[:8])
		case worktree.JobStatusTimeout:
			fmt.Printf("⏰ Timeout: %s\n", update.JobID[:8])
		}
	}
}

func (em *ExecutionManager) Stop() {
	if em.pool != nil {
		em.pool.Stop()
	}
}