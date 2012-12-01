if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start
end

require 'timeout'
require 'pty-recorder'
require 'expect'
require 'pry'

RSpec::Matchers.define :expect_match do |expected|
  match do |actual|
    Timeout::timeout(5) do
      if actual.respond_to?(:expect)
        actual.expect(expected)
      elsif actual.respond_to?(:string)
        actual.string =~ expected
      else
        actual.read_nonblock(1024) =~ expected
      end
    end
  end
end

module ChildHelpers
  def child(&block)
    @pid = fork do
      block.call
      exit! # exit without hooks
    end
    at_exit { terminate_child @pid }
  end

  def terminate_child(pid = @pid)
    return unless pid
    Process.kill(:HUP, pid)
    Process.waitpid(pid)
  rescue Errno::ESRCH, Errno::ECHILD
  end
end

RSpec.configure do |config|
  config.include ChildHelpers
end
