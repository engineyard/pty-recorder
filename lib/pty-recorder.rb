require 'pty'
require 'io/console' # for IO#raw!, #cooked!, #winsize

module PTY::Recorder
  NCHARS = 4096

  def self.spawn(command, options = {})
    stdin  = options[:stdin]  || $stdin
    stdout = options[:stdout] || $stdout

    PTY.spawn(command) do |cout, cin, pid|
      trap(:INT,  'IGNORE')
      trap(:HUP)   { safely_kill_process(:HUP, pid) }
      trap(:QUIT)  { safely_kill_process(:QUIT, pid) }
      trap(:WINCH) { set_winsize(cin, stdin) }

      set(stdin,:raw!)
      set_winsize(cin, stdin)

      res = catch(:eof) do
        read_write_loop({
          stdin => [options[:inlog],  cin   ].compact,
          cout  => [options[:outlog], stdout].compact,
        })
      end

      # close master to generate an EOF on child's stdin (otherwise
      # child won't exit and parent will hang in waitpid)
      cin.close
      Process.waitpid(pid)

      return res
    end
  ensure
    set(stdin,:cooked!)
    set(stdout,:cooked!)
  end

  private

  def self.set(obj, cmd)
    if obj.respond_to?(cmd)
      obj.send(cmd)
    end
  rescue
    # IO pipes don't like ioctl
  end

  def self.set_winsize(cin, stdin)
    if stdin.respond_to?(:winsize)
      cin.winsize = stdin.winsize
    end
  rescue
    # Can't set winsize. Uncooperative IO.
  end

  def self.read_write_loop(io_map)
    # select [read, write, exception]
    # We shouldn't have to worry about our write operations blocking.
    while rv = IO.select(io_map.keys, io_map.values.flatten, io_map.keys)
      ra, wa, ea = *rv

      if ra.any?
        ra.each do |reader|
          writers = io_map[reader] || throw(:eof, "Unknown fd")
          writers &= wa
          read_write(reader, writers)
        end
      end

      if ea.any?
        throw :eof, "select returned exception - #{ea.inspect}"
      end
    end

    throw :eof, "select returned nil"
  end

  def self.read_write(reader, writers)
    buf = reader.readpartial(NCHARS)
    throw :eof, "nil from #{reader.inspect}" if buf.nil?
    writers.each { |o| o << buf }
  rescue EOFError
    throw :eof, "EOF on #{reader.inspect}"
  rescue Errno::EIO
    throw :eof, "EIO on #{reader.inspect}"
  end

  def self.safely_kill_process(signal, pid)
    # check returns nil when the process is running
    PTY.check(pid) || Process.kill(signal, pid)
  rescue Errno::ESRCH, Errno::ECHILD
    # process is dead
  end

end
