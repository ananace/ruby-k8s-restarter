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

  module Handlers
    autoload :PodNotReady, 'k8s_restarter/handlers/pod_not_ready'
    autoload :PodStuckTerminating, 'k8s_restarter/handlers/pod_stuck_terminating'
  end
end
