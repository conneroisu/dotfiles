package scanner

import (
	"path/filepath"
	"regexp"
	"strings"
)

// shouldIgnoreDir determines if a directory should be ignored.
func (s *Scanner) shouldIgnoreDir(dirPath string, cfg Config) bool {
	realDirPath, err := filepath.Abs(dirPath)
	if err != nil {
		realDirPath = dirPath
	}

	// Check ignore directories
	for _, ignoreDir := range cfg.IgnoreDir {
		if s.matchesIgnoreDir(dirPath, realDirPath, ignoreDir) {
			return true
		}
	}

	// Check ignore globs
	for _, pattern := range cfg.IgnoreGlobs {
		if MatchesGlobPattern(dirPath, pattern) {
			return true
		}
	}

	return false
}

// matchesIgnoreDir checks if a directory matches an ignore pattern.
func (s *Scanner) matchesIgnoreDir(dirPath, realDirPath, ignoreDir string) bool {
	// Simple directory name match
	if !strings.Contains(ignoreDir, string(filepath.Separator)) {
		pathParts := strings.Split(dirPath, string(filepath.Separator))
		for _, part := range pathParts {
			if part == ignoreDir {
				return true
			}
		}
	}

	// Directory path suffix match
	if strings.HasSuffix(filepath.Dir(dirPath), string(filepath.Separator)+ignoreDir) {
		return true
	}

	// Full path match for complex ignore patterns
	if strings.Contains(ignoreDir, string(filepath.Separator)) {
		realIgnoreDir, _ := filepath.Abs(strings.TrimSuffix(ignoreDir, "/"))
		if strings.HasPrefix(realDirPath, realIgnoreDir) {
			return true
		}

		if strings.Contains(filepath.Dir(dirPath), strings.TrimSuffix(ignoreDir, "/")) {
			return true
		}
	}

	return false
}

// MatchesGlobPattern checks if a file path matches a glob pattern.
func MatchesGlobPattern(filePath, pattern string) bool {
	regexPattern := WildcardToRegex(pattern)
	regex, err := regexp.Compile(regexPattern)
	if err != nil {
		return false
	}
	
	// Try matching against both full path and just filename
	if regex.MatchString(filePath) {
		return true
	}
	
	// Extract filename and try matching
	if idx := strings.LastIndex(filePath, "/"); idx >= 0 {
		filename := filePath[idx+1:]
		return regex.MatchString(filename)
	}
	
	return regex.MatchString(filePath)
}

// WildcardToRegex converts a glob pattern to a regex pattern.
func WildcardToRegex(pattern string) string {
	escaped := regexp.QuoteMeta(pattern)
	escaped = strings.ReplaceAll(escaped, `\*`, `.*`)
	escaped = strings.ReplaceAll(escaped, `\?`, `.`)
	return escaped
}