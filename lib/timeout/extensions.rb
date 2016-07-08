require "timeout/extensions/version"
require "timeout"

# Core extensions to Thread
#
# Adds accessors to customize timeout and sleep within a thread,
# if you have a better friendlier implementation of both methods,
# or if your code breaks with the stdlib implementations.
#

module Timeout::Extensions
  module TimeoutMethods
    def timeout(*args, &block)
      return super unless Thread.current.respond_to?(:timeout_handler)
      if (timeout_handler = Thread.current.timeout_handler)
        timeout_handler.call(*args, &block)
      else
        super
      end
    end
  end

  module KernelMethods
    def sleep(*args)
      return super unless Thread.current.respond_to?(:sleep_handler)
      if (sleep_handler = Thread.current.sleep_handler)
        sleep_handler.call(*args)
      else
        super
      end
    end
  end

  # in order for prepend to work, I have to do it in the Timeout module singleton class
  class << ::Timeout
    prepend TimeoutMethods
  end

  # ditto for Kernel
  class << ::Kernel
    prepend KernelMethods
  end

  # this is an hack so that calling "sleep(2)" works. Amazingly, the message doesn't get
  # sent to Kernel.sleep code path.
  # https://bugs.ruby-lang.org/issues/12535
  #
  ::Object.prepend KernelMethods
end

module Timeout
  def self.backend(handler)
    return yield unless Thread.current.respond_to?(:timeout_handler)
    default_handler = Thread.current.timeout_handler
    begin
      Thread.current.timeout_handler = handler
      yield
    ensure
      Thread.current.timeout_handler = default_handler
    end
  end
end
