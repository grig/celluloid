require 'set'

module Celluloid
  # Allow methods to directly interact with the actor protocol
  class Receivers
    def initialize
      @receivers = Set.new
      @timers = Timers.new
    end

    # Receive an asynchronous message
    def receive(timeout = nil, &block)
      receiver = Receiver.new block

      if timeout
        receiver.timer = @timers.add(timeout) do
          @receivers.delete receiver
          receiver.resume
        end
      end

      @receivers << receiver
      Fiber.yield
    end

    # How long to wait until the next timer fires
    def wait_interval
      @timers.wait_interval
    end

    # Fire any pending timers
    def fire_timers
      @timers.fire
    end

    # Handle incoming messages
    def handle_message(message)
      receiver = @receivers.find { |r| r.match(message) }
      return unless receiver

      @receivers.delete receiver
      @timers.cancel receiver.timer if receiver.timer
      receiver.resume message
    end
  end

  # Methods blocking on a call to receive
  class Receiver
    attr_accessor :timer

    def initialize(block)
      @block = block
      @fiber = Fiber.current
      @timer = nil
    end

    # Match a message with this receiver's block
    def match(message)
      @block.call(message) if @block
    end

    def resume(message = nil)
      @fiber.resume message
    end
  end
end
