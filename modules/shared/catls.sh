#!/usr/bin/env bash

# Default values
dir="."
maxdepth=1
show_hidden=0

# Function to print usage information
usage() {
  echo "Usage: catls [OPTIONS] [DIRECTORY]"
  echo "List contents of files in the specified directory with filename headers"
  echo ""
  echo "Options:"
  echo "  -h, --help       Show this help message"
  echo "  -a, --all        Include hidden files"
  echo "  -r, --recursive  Recursively list files in subdirectories"
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
  
  # Get relative path from the specified directory
  rel_path="${file#$dir/}"
  if [ "$file" = "$rel_path" ]; then
    # If there was no change, we're in the current directory
    rel_path="$(basename "$file")"
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
    
    cat "$file"
    echo '```'
  fi
  
  echo ""
done <<< "$files"
