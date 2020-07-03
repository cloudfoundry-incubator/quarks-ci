#!/usr/bin/env ruby
# kurzschluss: exit early if git changes match pattern

def usage
  puts "Usage: #{$PROGRAM_NAME} git-dir task.sh"
  exit 1
end

def success
  exit 0
end

def debug(*args)
  STDERR.puts(args) if $VERBOSE
end

# true if pattern covers changed lines completely
def full_match(pattern, lines)
  return unless pattern

  debug('full_match if count equal:', lines.grep(/#{pattern}/))
  n = lines.grep(/#{pattern}/).count
  debug('line count:', lines.count, n)

  lines.count == n
end

# true if pattern does not match any line
def no_match(pattern, lines)
  return unless pattern

  debug('no_match if empty:', lines.grep(/#{pattern}/))
  lines.grep(/#{pattern}/).empty?
end

if $PROGRAM_NAME == __FILE__
  dir = ARGV[0] || ''
  if dir.empty? || !File.directory?(dir)
    puts 'missing git dir to check for changes'
    usage
  end

  task = ARGV[1] || ''
  if task.empty? || !File.executable?(task)
    puts 'missing task script which is conditionally executed'
    usage
  end

  Dir.chdir(dir) do
    next unless File.readable?('.git/resource/base_sha')

    # https://github.com/telia-oss/github-pr-resource#get
    base_sha = File.read('.git/resource/base_sha')
    lines = `git diff --name-only #{base_sha}`.split
    debug('git diff:', lines)

    # after excluding all lines matching the regex, exit if no lines are left
    success if full_match(ENV['SUCCEED_UNLESS_CHANGES_BEYOND'], lines)

    # if changes do not include any lines matching the regex, exit early
    success if no_match(ENV['SUCCEED_UNLESS_CHANGES_CONTAIN'], lines)
  end

  exec task, *ARGV[2..-1]
end
