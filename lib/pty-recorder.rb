require 'pty'
require 'io/console' # for IO#raw!, #cooked!, #winsize

class PTY::Recorder
  NCHARS = 4096

  def self.spawn(command, options = {})
    new(command, options).call
  end

  # Messy proof of concept for winsize and pty
  def initialize(command, options = {})
    @command = command
    @stdin   = options[:stdin]  || $stdin
    @stdout  = options[:stdout] || $stdout
    @inlog   = options[:inlog]
    @outlog  = options[:outlog]
  end

  def call
    spawn_command_in_pty do
      select_readable do |readable|

        case readable
        when @stdin  then write_input_to_child
        when @sshout then print_child_output
        else throw :eof, "Unknown fd"
        end

      end
    end
  end

  private

  def spawn_command_in_pty(&block)
    PTY.spawn(@command) do |sshout, sshin, pid|
      @sshout, @sshin, @pid = sshout, sshin, pid

      begin
        set_traps
        set_raw
        set_winsize

        res = catch(:eof) { yield }

        # close master to generate an EOF on child's @stdin (otherwise
        # child won't exit and parent will hang in waitpid)
        @sshin.close
        Process.waitpid(@pid)
        return res
      ensure
        set_cooked
      end
    end
  end

  # select [read, write, exception]
  # We shouldn't have to worry about our write operations blocking.
  def select_readable(&block)
    while rv = IO.select([@sshout, @stdin], [], [@sshout, @stdin])
      ra, wa, ea = *rv

      if ra.any?
        ra.each(&block)
      end

      if ea.any?
        throw :eof, "select returned exception - #{ea.inspect}"
      end
    end

    throw :eof, "select returned nil"
  end

  # write to stdin of child process
  def write_input_to_child
    text = @stdin.readpartial(NCHARS)
    throw :eof, "nil from stdin" if text.nil?
    @inlog << text if @inlog
    @sshin    << text
  rescue EOFError
    throw :eof, "EOF on stdin"
  rescue Errno::EIO
    throw :eof, "EIO on stdin"
  end

  # read child's stdout
  def print_child_output
    text = @sshout.readpartial(NCHARS)
    throw :eof, "nil from sshout" if text.nil?
    @outlog << text if @outlog
    @stdout    << text
  rescue EOFError
    throw :eof, "EOF on sshout"
  rescue Errno::EIO
    throw :eof, "EIO on sshout"
  end

  def set_traps
    trap(:HUP) { safely_kill_process(:HUP) }
    trap(:INT, 'IGNORE')
    trap(:QUIT) { safely_kill_process(:QUIT) }
    trap(:WINCH) { set_winsize }
  end

  def safely_kill_process(signal)
    # check returns nil when the process is running
    PTY.check(@pid) || Process.kill(signal, @pid)
  rescue Errno::ESRCH, Errno::ECHILD
    # process is dead
  end

  def set_raw
    if @stdin.respond_to?(:raw!)
      @stdin.raw! rescue nil # IO pipes don't like ioctl
    end
  end

  def set_cooked
    if @stdin.respond_to?(:cooked!)
      @stdin.cooked! rescue nil # IO pipes don't like ioctl
    end
    if @stdout.respond_to?(:cooked!)
      @stdout.cooked! rescue nil # IO pipes don't like ioctl
    end
  end

  def set_winsize
    if @stdin.respond_to?(:winsize)
      @sshin.winsize = @stdin.winsize
    end
  rescue
    # Can't set winsize. Uncooperative IO.
  end

end
