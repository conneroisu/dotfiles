#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use File::Basename;
use Cwd 'abs_path';
use Carp;

# Default ignore patterns (regex strings)
my @ignore_regex = (
    qr/\.git\//,
    qr/\.svn\//,
    qr/\.hg\//,
    qr/__pycache__\//,
    qr/\.pytest_cache\//,
    qr/\.mypy_cache\//,
    qr/\.tox\//,
    qr/\.venv\//,
    qr/\.coverage/,
    qr/\.DS_Store/,
    qr/\.idea\//,
    qr/\.vscode\//,
    qr/.*_templ\.go$/,
    qr/LICENSE$/,
    qr/LICENSE\.md$/,
    qr/LICENSE\.txt$/,
);

# Default ignore directories (strings)
my @ignore_dir = (
    "node_modules", ".direnv", "build", "dist", "target",
    "venv", "env", ".env", "vendor", ".bundle", "coverage",
);

# Command-line options
my $show_all          = 0;
my $recursive         = 0;
my $content_pattern   = "";
my $show_line_numbers = 0;
my $debug             = 0;

# User-provided patterns
my @include_regex;     # strings or qr// for include
my @extra_ignore_regex;
my @extra_ignore_dir;

GetOptions(
    'all|a'           => \$show_all,
    'recursive|r'     => \$recursive,
    'ignore-regex=s@' => \@extra_ignore_regex,
    'ignore-dir=s@'   => \@extra_ignore_dir,
    'regex=s@'        => \@include_regex,
    'pattern=s'       => \$content_pattern,
    'line-numbers|n'  => \$show_line_numbers,
    'debug'           => \$debug,
) or croak "Error in command line arguments\n";

# Merge user-specified ignores
push @ignore_regex, map { qr/$_/ } @extra_ignore_regex;
push @ignore_dir,    @extra_ignore_dir;

# Positional args: directory and optional files
my $directory     = shift @ARGV // ".";
my @forced_files  = @ARGV;

# If forced files given, add exact-match include patterns
for my $f (@forced_files) {
    if (-f $f) {
        my $b = basename($f);
        push @include_regex, qr/^\Q$b\E$/;
    }
}

die "Error: '$directory' is not a valid directory\n"
    unless -d $directory;

log_debug("Ignore dirs: @ignore_dir");
log_debug("Ignore regex: @ignore_regex");
log_debug("Include regex: @include_regex");

# Collect files
my @all_files;
find_files($directory, \@all_files);

@all_files = sort @all_files;
unless (@all_files) {
    print "No files found in directory: $directory\n";
    exit 0;
}

# Output XML
print "<files>\n";
for my $file (@all_files) {
    my $rel = File::Spec->abs2rel($file, $directory);
    next unless should_include($rel, \@include_regex);
    if (should_ignore($rel, \@ignore_regex, \@ignore_dir)) {
        log_debug("Ignoring file: $rel");
        next;
    }
    my $safe_path = xml_escape($rel);
    print qq{<file path="$safe_path">\n};
    if (is_binary($file)) {
        print "  <binary>true</binary>\n";
        print "  <content>[Binary file - contents not displayed]</content>\n";
    } else {
        my $type = xml_escape(guess_filetype($file));
        print "  <type>$type</type>\n";
        if (open my $fh, "<:encoding(UTF-8)", $file) {
            my @lines    = <$fh>;
            close $fh;
            my @filtered = filter_content(\@lines, $content_pattern);
            my $total    = @lines;
            my $count    = @filtered;
            my $limit    = 100;
            my $need_truncate = (!$content_pattern && $count > 1000);
            @filtered = @filtered[0..$limit-1] if $need_truncate;
            print "  <content>\n";
            for my $pair (@filtered) {
                my ($ln, $text) = @$pair;
                if ($show_line_numbers) {
                    printf("%4d| %s", $ln, $text);
                } else {
                    print $text;
                }
            }
            if ($need_truncate) {
                print "... (" . ($total - $limit) . " more lines)\n";
            }
            print "  </content>\n";
        } else {
            print "  <error>", xml_escape($!), "</error>\n";
        }
    }
    print "</file>\n";
}
print "</files>\n";

#------------------ Subroutines ------------------#

sub find_files {
    my ($dir, $files) = @_;
    opendir my $dh, $dir or do {
        warn "Cannot open '$dir': $!\n";
        return;
    };
    for my $entry (readdir $dh) {
        next if $entry eq '.' or $entry eq '..';
        next if !$show_all and $entry =~ /^\./;
        my $path = File::Spec->catfile($dir, $entry);
        if (-d $path) {
            if (should_ignore($path, \@ignore_regex, \@ignore_dir)) {
                log_debug("Ignoring directory: $path");
            } elsif ($recursive) {
                find_files($path, $files);
            }
        }
        elsif (-f $path) {
            push @$files, $path;
        }
    }
    closedir $dh;
}

sub wildcard_to_regex {
    my ($pat) = @_;
    $pat = quotemeta($pat);
    $pat =~ s/\\\*/.*/g;
    $pat =~ s/\\\?/./g;
    return $pat;
}

sub is_binary {
    my ($file) = @_;
    # Try 'file' command
    if (my $out = `file --brief --mime-type '$file' 2>/dev/null`) {
        return $out !~ m{^text/}i;
    }
    # Fallback: look for NUL bytes
    if (open my $fh, '<:raw', $file) {
        read($fh, my $buf, 1024);
        close $fh;
        return $buf =~ /\0/;
    }
    return 1;  # if we can't read it, assume binary
}

sub guess_filetype {
    my ($file) = @_;
    my %map = (
        sh      => 'bash', bash  => 'bash',
        py      => 'python',
        js      => 'javascript',
        html    => 'html',
        nix     => 'nix',
        css     => 'css',
        json    => 'json',
        md      => 'markdown',
        xml     => 'xml',
        c       => 'c',
        cpp     => 'cpp',
        h       => 'c',
        toml    => 'toml',
        hpp     => 'cpp',
        java    => 'java',
        rs      => 'rust',
        go      => 'go',
        rb      => 'ruby',
        php     => 'php',
        pl      => 'perl',
        sql     => 'sql',
        templ   => 'templ',
        yml     => 'yaml',
        yaml    => 'yaml',
    );
    my ($ext) = $file =~ /\.([^.]+)$/;
    return $map{lc $ext} // '';
}

sub should_include {
    my ($path, $patterns) = @_;
    return 1 unless @$patterns;
    my $base = basename($path);
    for my $pat (@$patterns) {
        if (ref $pat eq 'Regexp') {
            return 1 if $path =~ $pat;
        } else {
            if ($pat =~ /[\*\?]/) {
                my $re = qr/^@{[ wildcard_to_regex($pat) ) ]}$/;
                return 1 if $base =~ $re or $path =~ $re;
            } else {
                my $re = qr/$pat/;
                return 1 if $path =~ $re;
            }
        }
    }
    return 0;
}

sub should_ignore {
    my ($path, $pat_regex, $pat_dirs) = @_;
    my $real = get_real_path($path);
    # directory-name and path-based ignores
    my @parts = File::Spec->splitdir($path);
    for my $d (@$pat_dirs) {
        # ignore matching directory names
        if ($d !~ m{/} and grep { $_ eq $d } @parts) {
            return 1;
        }
        # ignore path prefixes
        if ($d =~ m{/}) {
            my $ignore_root = get_real_path($d);
            if (defined $ignore_root and index($real, $ignore_root) == 0) {
                return 1;
            }
        }
    }
    # regex-based ignores
    for my $re (@$pat_regex) {
        return 1 if $path =~ $re;
    }
    return 0;
}

sub get_real_path {
    my ($p) = @_;
    for my $cmd (["realpath", $p], ["readlink", "-f", $p]) {
        if (my $out = qx{$cmd->[0] '$cmd->[1]' 2>/dev/null}) {
            chomp $out;
            return $out if -e $out;
        }
    }
    return abs_path($p);
}

sub filter_content {
    my ($lines, $pattern) = @_;
    my @out;
    if ($pattern) {
        my $re = qr/@{[ wildcard_to_regex($pattern) ]}/;
        for my $i (0 .. $#$lines) {
            push @out, [ $i+1, $lines->[$i] ] if $lines->[$i] =~ $re;
        }
    } else {
        for my $i (0 .. $#$lines) {
            push @out, [ $i+1, $lines->[$i] ];
        }
    }
    return @out;
}

sub xml_escape {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    $s =~ s/'/&apos;/g;
    return $s;
}

sub log_debug {
    return unless $debug;
    warn "Debug: ", @_;
}
