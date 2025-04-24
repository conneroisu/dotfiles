#!/usr/bin/env bash
# Default values
dir="."
maxdepth=1
show_hidden=0
# Arrays to store patterns
ignore_patterns=()
ignore_dirs=()
include_patterns=()

# Function to print usage information
usage() {
  echo "Usage: catls [OPTIONS] [DIRECTORY]"
  echo "List contents of files in the specified directory with filename headers"
  echo ""
  echo "Options:"
  echo "  -h, --help       Show this help message"
  echo "  -a, --all        Include hidden files"
  echo "  -r, --recursive  Recursively list files in subdirectories"
  echo "  --ignore-regex PATTERN  Ignore files matching PATTERN (can be used multiple times)"
  echo "  --ignore-dir DIR        Ignore directory DIR (can be used multiple times)"
  echo "  --regex PATTERN         Only include files matching PATTERN (can be used multiple times)"
  echo ""
  echo "If DIRECTORY is not provided, the current directory is used."
  exit 1
}

# Function to check if a file is binary
is_binary() {
  if file "$1" | grep -q "text"; then
    return 1  # Not binary (text file)
  else
    return 0  # Binary file
  fi
}

# Function to guess file type based on extension
guess_filetype() {
  local ext="${1##*.}"
  case "$ext" in
    sh|bash)
      echo "bash"
      ;;
    py)
      echo "python"
      ;;
    js)
      echo "javascript"
      ;;
    html)
      echo "html"
      ;;
    nix)
      echo "nix"
      ;;
    css)
      echo "css"
      ;;
    json)
      echo "json"
      ;;
    md)
      echo "markdown"
      ;;
    xml)
      echo "xml"
      ;;
    c)
      echo "c"
      ;;
    cpp)
      echo "cpp"
      ;;
    h)
      echo "c"
      ;;
    toml)
      echo "toml"
      ;;
    hpp)
      echo "cpp"
      ;;
    java)
      echo "java"
      ;;
    rs)
      echo "rust"
      ;;
    go)
      echo "go"
      ;;
    rb)
      echo "ruby"
      ;;
    php)
      echo "php"
      ;;
    pl)
      echo "perl"
      ;;
    sql)
      echo "sql"
      ;;
    templ)
      echo "templ"
      ;;
    yml|yaml)
      echo "yaml"
      ;;
    *)
      echo ""  # No specific type hint
      ;;
  esac
}

# Function to check if a file should be included based on patterns
should_include() {
  local file="$1"
  
  # If no include patterns specified, include all files
  if [ ${#include_patterns[@]} -eq 0 ]; then
    return 0  # Include (true)
  fi
  
  # Check if file matches any include pattern
  for pattern in "${include_patterns[@]}"; do
    if [[ "$file" =~ $pattern ]]; then
      return 0  # Include (true)
    fi
  done
  
  return 1  # Don't include (false)
}

# Function to check if a file matches any ignore pattern or is in an ignored directory
should_ignore() {
  local file="$1"
  
  # Check if file matches any regex pattern
  for pattern in "${ignore_patterns[@]}"; do
    if [[ "$file" =~ $pattern ]]; then
      return 0  # Should ignore (true)
    fi
  done
  
  # Check if file is in any ignored directory
  for ignored_dir in "${ignore_dirs[@]}"; do
    # Normalize paths for comparison
    local norm_dir="${ignored_dir%/}"
    
    # Check for exact directory match or if it's a subdirectory
    if [[ "$file" == "$norm_dir" ]] || [[ "$file" == "$norm_dir/"* ]] || [[ "$file" =~ ^"$norm_dir"/? ]]; then
      return 0  # Should ignore (true)
    fi
  done
  
  return 1  # Should not ignore (false)
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -a|--all)
      show_hidden=1
      shift
      ;;
    -r|--recursive)
      maxdepth=999
      shift
      ;;
    --ignore-regex)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        ignore_patterns+=("$2")
        shift 2
      else
        echo "Error: Argument for $1 is missing"
        usage
      fi
      ;;
    --ignore-dir)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        ignore_dirs+=("$2")
        shift 2
      else
        echo "Error: Argument for $1 is missing"
        usage
      fi
      ;;
    --regex)
      if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
        include_patterns+=("$2")
        shift 2
      else
        echo "Error: Argument for $1 is missing"
        usage
      fi
      ;;
    -*)
      echo "Error: Unknown option: $1"
      usage
      ;;
    *)
      dir="$1"
      shift
      ;;
  esac
done

# Check if the directory exists
if [ ! -d "$dir" ]; then
  echo "Error: '$dir' is not a valid directory."
  exit 1
fi

# Set up find command options
find_opts=(-maxdepth "$maxdepth" -type f)

# If we're not showing hidden files, exclude them
if [ "$show_hidden" -eq 0 ]; then
  find_opts+=(-not -path "*/\.*")
fi

# Find all files in the directory based on options and sort them alphabetically
files=$(find "$dir" "${find_opts[@]}" | sort)

# If no files found
if [ -z "$files" ]; then
  echo "No files found in directory: $dir"
  exit 0
fi

# For each file, print filename and contents in a code block
while IFS= read -r file; do
  # Skip empty lines
  [ -z "$file" ] && continue
  
  # Skip files not matching include patterns
  if ! should_include "$file"; then
    continue
  fi
  
  # Skip files matching ignore patterns or in ignored directories
  if should_ignore "$file"; then
    continue
  fi
  
  # Get relative path from the specified directory
  if [[ "$dir" == "." ]]; then
    rel_path="$file"
  else
    rel_path="${file#$dir/}"
    if [ "$file" = "$rel_path" ]; then
      # If there was no change, we're in the current directory
      rel_path="$(basename "$file")"
    fi
  fi
  
  echo "### $rel_path"
  
  if is_binary "$file"; then
    echo "[Binary file - contents not displayed]"
  else
    # Get file type hint
    filetype=$(guess_filetype "$file")
    
    if [ -n "$filetype" ]; then
      echo '```'"$filetype file='$rel_path'"
    else
      echo '```'
    fi
    
    # If it has over 1000 lines, just print the first 100
    if [ "$(wc -l "$file" | cut -d ' ' -f 1)" -gt 1000 ]; then
      cat "$file" | head -n 100
      echo "... ($(wc -l "$file" | cut -d ' ' -f 1) - 100 more lines)"
      echo '```'
    else
      cat "$file"
      echo '```'
    fi
  fi
  
  echo ""
done <<< "$files"
