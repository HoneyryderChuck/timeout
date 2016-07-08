require "timeout/extensions"
require "celluloid"

module Celluloid
  ####################
  #
  # Celluloid Monkey-Patch Alert!!!!
  # I would really like to remove this but, but I first need this pull request accepted:
  # https://github.com/celluloid/celluloid/pull/491
  #
  # These methods have kept the same functionality for quite some time, therefore are quite stable,
  # I just moved the locations and updated/corrected the method signatures.
  #
  # Why the monkey-patch? The Celluloid::Actor#timeout method from celluloid core doesn't respect
  # the Timeout.timeout signature, that is, add the possibility of passing a custom exception. Also,
  # a general timeout for the Celluloid scope should also be publicly acessibly, and (IMO) therefore defined
  # as a module method.
  #
  ###################

  def self.timeout(duration, klass = nil)
    bt = caller
    task = Task.current
    klass ||= TaskTimeout
    timers = Thread.current[:celluloid_actor].timers
    timer = timers.after(duration) do
      exception = klass.new("execution expired")
      exception.set_backtrace bt
      task.resume exception
    end
    yield
  ensure
    timer.cancel if timer
  end

  class Actor
    # Using the module method now instead of doing everything by itself.
    def timeout(*args)
      Celluloid.timeout(*args) { yield }
    end
    private :timeout
  end

  # END OF MONKEY PATCHES! #

  # This is how it works for celluloid: methods defined at the thread level. Each subsequent
  # Timeout.timeout of sleep call will go through them.
  module TimeoutExtensions
    def timeout_handler
      Celluloid.method(:timeout)
    end

    def sleep_handler
      Celluloid.method(:sleep)
    end
  end

  Thread.__send__(:include, TimeoutExtensions)
end
