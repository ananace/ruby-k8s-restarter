# frozen_string_literal: true

require 'time'

module K8sRestarter::Handlers
  class PodStuckTerminating < K8sRestarter::Handler
    desc <<~DOC
      The timeout value in seconds before counting a terminating pod as "stuck".
      A negative value will be counted as a multiplier of the termination grace period.
    DOC
    parameter :timeout_grace, Numeric, 24 * 60 * 60

    parameter :also_jobs, :bool, false
    parameter :also_failed, :bool, true

    def applicable?(pod)
      return false unless pod.metadata.deletionTimestamp
      return false if !also_jobs && pod.metadata.ownerReference&.any? { |ref| ref.apiVersion == 'batch/v1' && ref.kind == 'Job' }

      # return false if !also_failed && pod.phase

      super
    end

    def update(pod)
      timeout = if timeout_grace >= 0
                  timeout_grace
                else
                  pod.spec.terminationGracePeriodSeconds * -timeout_grace
                end

      return unless (dur = Time.now - Time.parse(pod.metadata.deletionTimestamp)) >= timeout

      logger.info "Pod #{pod} still terminating after #{dur.to_duration}, marking for force deletion"
      mark(pod, :force_delete)
    end
  end
end
