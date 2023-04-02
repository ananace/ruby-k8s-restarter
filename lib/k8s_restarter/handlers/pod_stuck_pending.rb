# frozen_string_literal: true

require 'time'

module K8sRestarter::Handlers
  class PodStuckPending < K8sRestarter::Handler
    desc <<~DOC
      The timeout value in seconds before counting a pending pod as "stuck".
    DOC
    parameter :timeout, Numeric, 24 * 60 * 60

    parameter :also_daemonsets, :bool, false

    def applicable?(pod)
      return false unless pod.phase == :pending
      return false if !also_daemonsets && pod.metadata.ownerReferences&.any? { |ref| ref.apiVersion == 'apps/v1' && ref.kind == 'DaemonSet' }

      super
    end

    def update(pod)
      return unless (dur = Time.now - Time.parse(pod.metadata.creationTimestamp)) >= timeout

      logger.info "Pod #{pod} still pending after #{dur.to_duration}, marking for deletion"
      mark(pod, :delete)
    end
  end
end
