package results

import (
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/executor"
)

// Summary represents aggregated results from job execution
type Summary struct {
	TotalJobs      int                   `json:"total_jobs"`
	SuccessfulJobs int                   `json:"successful_jobs"`
	FailedJobs     int                   `json:"failed_jobs"`
	TimeoutJobs    int                   `json:"timeout_jobs"`
	TotalDuration  time.Duration         `json:"total_duration"`
	Results        []*executor.JobResult `json:"results"`
	FailedResults  []*executor.JobResult `json:"failed_results"`
	StartTime      time.Time             `json:"start_time"`
	EndTime        time.Time             `json:"end_time"`
}

// Aggregator processes and aggregates job results
type Aggregator struct{}

// NewAggregator creates a new result aggregator
func NewAggregator() *Aggregator {
	return &Aggregator{}
}

// ProcessResults processes a list of job results and returns a summary
func (a *Aggregator) ProcessResults(results []*executor.JobResult) *Summary {
	if len(results) == 0 {
		now := time.Now()
		return &Summary{
			TotalJobs: 0,
			StartTime: now,
			EndTime:   now,
		}
	}

	now := time.Now()
	summary := &Summary{
		TotalJobs: len(results),
		Results:   results,
		StartTime: now,
		EndTime:   now,
	}

	// Find earliest start time and latest end time
	for i, result := range results {
		if i == 0 || result.StartTime.Before(summary.StartTime) {
			summary.StartTime = result.StartTime
		}
		if i == 0 || result.EndTime.After(summary.EndTime) {
			summary.EndTime = result.EndTime
		}

		// Count by status
		switch result.Status {
		case executor.StatusSuccess:
			summary.SuccessfulJobs++
		case executor.StatusFailed:
			summary.FailedJobs++
			summary.FailedResults = append(summary.FailedResults, result)
		case executor.StatusTimeout:
			summary.TimeoutJobs++
			summary.FailedResults = append(summary.FailedResults, result)
		}
	}

	summary.TotalDuration = summary.EndTime.Sub(summary.StartTime)

	return summary
}

// GetSuccessRate returns the success rate as a percentage
func (s *Summary) GetSuccessRate() float64 {
	if s.TotalJobs == 0 {
		return 0.0
	}
	return float64(s.SuccessfulJobs) / float64(s.TotalJobs) * 100.0
}

// HasFailures returns true if there were any failures
func (s *Summary) HasFailures() bool {
	return len(s.FailedResults) > 0
}

// GetAverageDuration returns the average job duration
func (s *Summary) GetAverageDuration() time.Duration {
	if s.TotalJobs == 0 {
		return 0
	}

	var totalDuration time.Duration
	for _, result := range s.Results {
		totalDuration += result.Duration
	}

	return totalDuration / time.Duration(s.TotalJobs)
}

// GetSlowestJob returns the job with the longest duration
func (s *Summary) GetSlowestJob() *executor.JobResult {
	if len(s.Results) == 0 {
		return nil
	}

	slowest := s.Results[0]
	for _, result := range s.Results[1:] {
		if result.Duration > slowest.Duration {
			slowest = result
		}
	}

	return slowest
}

// GetFastestJob returns the job with the shortest duration
func (s *Summary) GetFastestJob() *executor.JobResult {
	if len(s.Results) == 0 {
		return nil
	}

	fastest := s.Results[0]
	for _, result := range s.Results[1:] {
		if result.Duration < fastest.Duration {
			fastest = result
		}
	}

	return fastest
}
