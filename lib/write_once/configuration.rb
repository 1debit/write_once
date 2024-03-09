# frozen_string_literal: true

require 'logger'

module WriteOnce
  class Configuration
    attr_accessor :enforce_errors, :logger

    def initialize
      @enforce_errors = true
      @logger = Logger.new(STDOUT)
    end
  end
end
