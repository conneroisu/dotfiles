package worktree

import "time"

// Worktree represents a Git worktree
type Worktree struct {
	Name      string    `json:"name"`       // Project/directory name
	Path      string    `json:"path"`       // Absolute path to worktree
	Branch    string    `json:"branch"`     // Current branch name
	IsDirty   bool      `json:"is_dirty"`   // Has uncommitted changes
	IsTemp    bool      `json:"is_temp"`    // Is a temporary worktree created by par
	RemoteURL string    `json:"remote_url"` // Remote origin URL
	LastUsed  time.Time `json:"last_used"`  // Last time this worktree was used
}

// Status represents the status of a worktree validation
type Status int

const (
	StatusValid Status = iota
	StatusInvalid
	StatusDirty
	StatusMissingDeps
	StatusNoGit
)

// String returns string representation of status
func (s Status) String() string {
	switch s {
	case StatusValid:
		return "valid"
	case StatusInvalid:
		return "invalid"
	case StatusDirty:
		return "dirty"
	case StatusMissingDeps:
		return "missing_deps"
	case StatusNoGit:
		return "no_git"
	default:
		return "unknown"
	}
}

// ValidationResult contains the result of worktree validation
type ValidationResult struct {
	Worktree *Worktree
	Status   Status
	Issues   []string
}