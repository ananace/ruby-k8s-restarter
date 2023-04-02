# frozen_string_literal: true

require 'k8s_restarter/version'
require 'k8s_restarter/client'
require 'k8s_restarter/config'
require 'k8s_restarter/handler'
require 'k8s_restarter/pod'
require 'k8s_restarter/util'
require 'k8s-ruby'
require 'logging'

module K8sRestarter
  class Error < StandardError; end

  # Pod handlers
  module Handlers
    def self.const_defined?(name)
      file_name = "#{name.to_s.underscore}.rb"
      File.exist? File.join(__dir__, 'k8s_restarter/handlers', file_name)
    end

    def self.const_missing(name)
      file_name = name.to_s.underscore
      require File.join(__dir__, 'k8s_restarter/handlers', file_name)
      const_get(name)
    end
  end
end
