require "timeout/extensions"

module MyAwesomeJob
  def self.perform(i)
    # let's force fails when job takes more than 3 seconds
    timeout(i) do
      sleep i # perform incredibly heavy job
    end
  rescue => e
    puts "job failed: #{e.message}"
  end
end

module IgnoreOddTimeout
  CustomTimeoutError = Class.new(RuntimeError)
  def self.call(sec, *)
    if sec && sec.odd?
      puts "#{sec} is odd, not timing out"
    else
      puts "pretending to wait for #{sec} seconds..."
    end
    yield
  end
end

Array(5.times).map do |i|
  Thread.start do
    Timeout.backend(IgnoreOddTimeout) do
      MyAwesomeJob.perform(i)
    end
  end
end.map(&:join)
