#!/usr/bin/env ruby
require 'optparse'
require 'pathname'
require 'cgi'

# Class to hold command line arguments
class Args
  attr_accessor :show_all, :recursive, :debug, :ignore_regex, :ignore_dir,
                :include_regex, :directory, :files, :content_pattern, :show_line_numbers

  def initialize
    @show_all = false
    @recursive = false
    @debug = false
    # Default common directories to ignore
    @ignore_regex = [
      /\.git\//,
      /\.svn\//,
      /\.hg\//,
      /__pycache__\//,
      /\.pytest_cache\//,
      /\.mypy_cache\//,
      /\.tox\//,
      /\.venv\//,
      /\.coverage/,
      /\.DS_Store/,
      /\.idea\//,
      /\.vscode\//,
      /.*_templ\.go$/,  # Added pattern to ignore *_templ.go files
      /LICENSE$/,       # Ignore LICENSE files
      /LICENSE\.md$/,   # Ignore LICENSE.md files
      /LICENSE\.txt$/,  # Ignore LICENSE.txt files
    ]
    # Default common directories to ignore
    @ignore_dir = [
      "node_modules",
      ".direnv",
      "build",
      "dist",
      "target",
      "venv",
      "env",
      ".env",
      "vendor",
      ".bundle",
      "coverage",
    ]
    @include_regex = []
    @directory = "."
    @files = []
    @content_pattern = ""
    @show_line_numbers = false
  end
end

# Convert a shell-style wildcard pattern to a regex pattern
def wildcard_to_regex(pattern)
  # Escape special regex characters except * and ?
  result = Regexp.escape(pattern)
  # Convert shell wildcards to regex equivalents
  result = result.gsub(/\\\*/, '.*').gsub(/\\\?/, '.')
  result
end

# Check if a file is binary using the 'file' command
def is_binary(file_path)
  begin
    result = `file "#{file_path}"`
    return !result.downcase.include?("text")
  rescue StandardError
    # If the 'file' command fails, try a simple binary check
    begin
      File.open(file_path, "rb") do |f|
        chunk = f.read(1024)
        return chunk.include?("\0")
      end
    rescue StandardError
      return true  # Assume binary if we can't check
    end
  end
end

# Guess file type based on extension
def guess_filetype(file_path)
  ext = File.extname(file_path).downcase.delete_prefix(".").strip

  filetypes = {
    "sh" => "bash",
    "bash" => "bash",
    "rb" => "ruby",
    "py" => "python",
    "js" => "javascript",
    "html" => "html",
    "nix" => "nix",
    "css" => "css",
    "json" => "json",
    "md" => "markdown",
    "xml" => "xml",
    "c" => "c",
    "cpp" => "cpp",
    "h" => "c",
    "toml" => "toml",
    "hpp" => "cpp",
    "java" => "java",
    "rs" => "rust",
    "go" => "go",
    "php" => "php",
    "pl" => "perl",
    "sql" => "sql",
    "templ" => "templ",
    "yml" => "yaml",
    "yaml" => "yaml",
  }

  filetypes[ext] || ""
end

# Check if a file should be included based on patterns
def should_include(file_path, include_patterns)
  return true if include_patterns.empty?  # Include all files if no patterns specified

  # Get just the filename portion for simpler matching
  filename = File.basename(file_path)

  include_patterns.each do |pattern|
    # Handle shell-style wildcards by converting to regex
    if pattern.include?("*") || pattern.include?("?")
      # Convert shell wildcard to regex pattern
      regex_pattern = wildcard_to_regex(pattern)
      regex = Regexp.new(regex_pattern)
      return true if regex.match?(filename) || regex.match?(file_path)
    # Regular regex pattern
    elsif Regexp.new(pattern).match?(file_path)
      return true
    end
  end

  false
end

# Get the real absolute path using shell commands
def get_real_path(path)
  begin
    # First try with realpath which is common on most systems
    result = `realpath "#{path}" 2>/dev/null`.strip
    return result unless result.empty?
    
    # If realpath fails, try readlink -f
    result = `readlink -f "#{path}" 2>/dev/null`.strip
    return result unless result.empty?
  rescue StandardError
    # Fall back to Ruby's implementation if shell commands fail
  end
  
  # If all shell commands fail, use Ruby's equivalent
  Pathname.new(path).realpath.to_s
rescue
  File.expand_path(path)
end

# Check if a file matches any ignore pattern or is in an ignored directory
def should_ignore(file_path, ignore_patterns, ignore_dirs)
  # Use shell commands to get real paths for file
  real_file_path = get_real_path(file_path)
  
  # Check if the file matches basic filename checks for ignored dirs
  ignore_dirs.each do |ignore_dir|
    # Simple case: exact directory name match (like 'node_modules')
    if !ignore_dir.include?(File::SEPARATOR) && file_path.split(File::SEPARATOR).include?(ignore_dir)
      return true
    end
    
    # Check if the directory portion ends with the ignore_dir
    if File.dirname(file_path).end_with?(File::SEPARATOR + ignore_dir)
      return true
    end
    
    # For path-like ignore directories (like ./pkg/lzma/)
    if ignore_dir.include?(File::SEPARATOR)
      # Use shell command to resolve the ignore_dir path
      real_ignore_dir = get_real_path(ignore_dir.chomp('/'))
      
      # Check if file_path starts with ignore_dir (bash-like comparison)
      if real_file_path.start_with?(real_ignore_dir)
        return true
      end
      
      # Check if ignore_dir is a suffix of any directory component
      dir_path = File.dirname(file_path)
      if dir_path.include?(ignore_dir.chomp('/'))
        return true
      end
    end
  end
  
  # Check if file matches any regex pattern
  ignore_patterns.each do |pattern|
    return true if pattern.match?(file_path)
  end

  false
end

# Parse command line arguments
def parse_args
  args = Args.new
  
  option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: catls.rb [options] [directory] [files]"
    
    opts.on("-a", "--all", "Include hidden files") do
      args.show_all = true
    end
    
    opts.on("-r", "--recursive", "Recursively list files in subdirectories") do
      args.recursive = true
    end
    
    opts.on("--ignore-regex PATTERN", "Ignore files matching PATTERN (can be used multiple times)") do |pattern|
      args.ignore_regex << Regexp.new(pattern)
    end
    
    opts.on("--ignore-dir DIR", "Ignore directory DIR (can be used multiple times). Can be a directory name or path. Use './path/to/dir' for relative paths.") do |dir|
      args.ignore_dir << dir
    end
    
    opts.on("--regex PATTERN", "Only include files matching PATTERN (can be used multiple times)") do |pattern|
      args.include_regex << pattern
    end
    
    opts.on("--pattern PATTERN", "Only show lines matching glob PATTERN (e.g., '*import*', 'def *')") do |pattern|
      args.content_pattern = pattern
    end
    
    opts.on("-n", "--line-numbers", "Show line numbers") do
      args.show_line_numbers = true
    end
    
    opts.on("--debug", "Enable debug output") do
      args.debug = true
    end
    
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  
  # Handle unknown arguments
  begin
    # Parse the known options
    remaining_args = option_parser.parse(ARGV)
    
    # First non-option argument is the directory
    if !remaining_args.empty?
      args.directory = remaining_args.shift
    end
    
    # Remaining arguments are files
    remaining_args.each do |arg|
      if File.file?(arg)
        args.files << arg
      else
        # It might be a pattern, add to regex
        args.include_regex << arg
      end
    end
    
    # Process shell-expanded files
    args.files.each do |file|
      # If it's a path, use the full path for matching
      if File.exist?(file)
        # Use the basename for matching in our file list
        basename = File.basename(file)
        # Add an exact match regex
        args.include_regex << "^#{Regexp.escape(basename)}$"
      end
    end
  rescue OptionParser::ParseError => e
    puts "Error: #{e}"
    puts option_parser
    exit(1)
  end
  
  args
end

# Main function
def main
  # Parse command-line arguments
  args = parse_args
  
  # Set up debug mode based on command line argument
  ENV["CATLS_DEBUG"] = "1" if args.debug
  
  # Set up directory and check if it exists
  directory = args.directory
  unless File.directory?(directory)
    puts "Error: '#{directory}' is not a valid directory."
    exit(1)
  end
  
  # Special handling for --ignore-dir to match shell behavior
  # If we receive paths with ./ prefix, convert them to use basenames
  args.ignore_dir.map! do |ignore_dir|
    if ENV["CATLS_DEBUG"]
      STDERR.puts "Debug: Processing ignore dir: #{ignore_dir}"
    end
    
    # Strip trailing slashes for consistency
    ignore_dir.chomp('/')
  end
  
  # Find all files in the directory based on options
  files = []
  
  # Calculate the proper maxdepth value
  maxdepth = args.recursive ? Float::INFINITY : 1
  
  # Debug output for ignored directories
  if ENV["CATLS_DEBUG"]
    STDERR.puts "Debug: Ignoring directories: #{args.ignore_dir}"
    STDERR.puts "Debug: Raw ignore directories from arguments: #{args.ignore_dir}"
  end
  
  # Walk through the directory structure
  dir_stack = [[directory, 0]]  # [path, depth]
  while !dir_stack.empty?
    current_dir, current_depth = dir_stack.pop
    
    # Skip if we've gone too deep
    next if current_depth >= maxdepth
    
    begin
      entries = Dir.entries(current_dir).sort
      
      # Process each entry
      entries.each do |entry|
        next if entry == "." || entry == ".."
        
        # Skip hidden entries if not showing all
        next if !args.show_all && entry.start_with?(".")
        
        full_path = File.join(current_dir, entry)
        
        if File.directory?(full_path)
          # Check if this directory should be ignored
          if !should_ignore(full_path, args.ignore_regex, args.ignore_dir)
            dir_stack.push([full_path, current_depth + 1])
          elsif ENV["CATLS_DEBUG"]
            STDERR.puts "Debug: Ignoring directory: #{full_path}"
          end
        elsif File.file?(full_path)
          files << full_path
        end
      end
    rescue => e
      STDERR.puts "Error accessing directory #{current_dir}: #{e.message}"
    end
  end
  
  # Sort files alphabetically
  files.sort!
  
  # If no files found
  if files.empty?
    puts "No files found in directory: #{directory}"
    exit(0)
  end
  
  # Print XML header once
  puts '<files>'
  
  # For each file, print filename and contents in XML format
  files.each do |file_path|
    # Get relative path from the specified directory
    rel_path = (directory == ".") ? file_path : Pathname.new(file_path).relative_path_from(Pathname.new(directory)).to_s
    
    # Skip files not matching include patterns
    next unless should_include(rel_path, args.include_regex)
    
    # Skip files matching ignore patterns or in ignored directories
    if should_ignore(rel_path, args.ignore_regex, args.ignore_dir)
      if ENV["CATLS_DEBUG"]
        STDERR.puts "Debug: Ignoring file: #{rel_path}"
      end
      next
    end
    
    # XML escape the path for safety
    safe_path = CGI.escape_html(rel_path)
    
    puts "<file path=\"#{safe_path}\">"
    
    if is_binary(file_path)
      puts '  <binary>true</binary>'
      puts '  <content>[Binary file - contents not displayed]</content>'
    else
      # Get file type hint
      filetype = guess_filetype(file_path)
      puts "  <type>#{CGI.escape_html(filetype)}</type>"
      
      begin
        content = File.readlines(file_path, encoding: 'UTF-8', invalid: :replace)
        
        # Count total lines
        line_count = content.size
        
        # Filter content based on pattern if provided
        filtered_content = []
        if !args.content_pattern.empty?
          begin
            # Convert glob pattern to regex
            regex_pattern = wildcard_to_regex(args.content_pattern)
            pattern = Regexp.new(regex_pattern)
            content.each_with_index do |line, i|
              if pattern.match?(line)
                filtered_content << [i + 1, line]
              end
            end
          rescue RegexpError => e
            puts "    <error>Error in pattern: #{CGI.escape_html(e.to_s)}</error>"
            filtered_content = content.each_with_index.map { |line, i| [i + 1, line] }
          end
        else
          filtered_content = content.each_with_index.map { |line, i| [i + 1, line] }
        end
        
        # Count filtered lines
        filtered_count = filtered_content.size
        
        # Determine if we should limit displayed lines
        if filtered_count > 1000 && args.content_pattern.empty?
          # If no pattern and many lines, just show first 100
          to_display = filtered_content[0...100]
          print_trailing_message = true
        else
          # Otherwise show all filtered lines
          to_display = filtered_content
          print_trailing_message = false
        end
        
        puts '  <content>'
        # Print the content with optional line numbers
        to_display.each do |line_num, line|
          if args.show_line_numbers
            print "#{line_num.to_s.rjust(4)}| #{line}"
          else
            print line
          end
        end
        
        # Print message about omitted lines if needed
        if print_trailing_message
          puts "... (#{line_count - 100} more lines)"
        end
        
        puts '  </content>'
      rescue => e
        puts "  <error>#{CGI.escape_html(e.to_s)}</error>"
      end
    end
    
    puts '</file>'
  end
  
  # Print XML footer
  puts '</files>'
end

# Run the main function if this script is executed directly
main if __FILE__ == $PROGRAM_NAME
