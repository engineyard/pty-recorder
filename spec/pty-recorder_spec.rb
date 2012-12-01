require 'spec_helper'

describe PTY::Recorder do
  TEST_TIMEOUT = 20

  before do
    @stdin_reader, @stdin = IO.pipe
    @stdout, @stdout_writer = IO.pipe
    @inlog, @inlog_writer = IO.pipe
    @outlog, @outlog_writer = IO.pipe

    @command = "irb --simple-prompt"
    @recorder = PTY::Recorder.new( @command, {
      stdin: @stdin_reader,
      stdout: @stdout_writer,
      inlog: @inlog_writer,
      outlog: @outlog_writer
    })

    child do
      @stdin.close
      @stdout.close
      @inlog.close
      @outlog.close
      @recorder.call
    end

    @stdin_reader.close
    @stdout_writer.close
    @inlog_writer.close
    @outlog_writer.close
  end

  after do
    terminate_child
  end

  it 'records output' do
    Timeout::timeout(TEST_TIMEOUT) do
      @stdout.expect(/>> /) do |r|
        @stdin.puts('puts "hi"')
      end
      @stdout.should expect_match(/hi[\r\n]+=> nil/)
      @stdin.puts('exit')
    end
    @outlog.should expect_match(/hi[\r\n]+=> nil/)
  end

  it 'records input' do
    Timeout::timeout(TEST_TIMEOUT) do
      @stdout.expect(/>> /) do |r|
        @stdin.puts('puts "hi"')
      end
      @stdout.should expect_match(/hi[\r\n]+=> nil/)
      @stdin.puts('exit')
    end
    @inlog.should expect_match(/puts "hi"\n/)
  end

  it 'receives output sent to stderr' do
    Timeout::timeout(TEST_TIMEOUT) do
      @stdout.expect(/>> /) do |r|
        @stdin.puts('$stderr.puts "err"')
      end
      @stdout.should expect_match(/err[\r\n]+/)
      @stdin.puts('exit')
    end
    @outlog.should expect_match(/err[\r\n]+/)
  end
end
