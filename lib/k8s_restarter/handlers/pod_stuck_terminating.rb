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

    def update(pod)
      return if pod.metadata.labels[:'job-name'] && !also_jobs

      if !storage(pod).terminating_at
        if pod.metadata.deletionTimestamp
          storage(pod).terminating_at = Time.parse(pod.metadata.deletionTimestamp)
        elsif %w[Failed Unknown].include?(pod.phase) && also_failed
          storage(pod).terminating_at = Time.now
        else
          node = pod.node
          node_ready = node.status.conditions.find do |cond|
            cond.type == 'Ready' && cond.status.downcase != 'true'
          end

          storage(pod).terminating_at = Time.now unless node_ready
        end
      end

      return unless storage(pod).terminating_at

      if timeout_grace >= 0
        timeout = timeout_grace
      else
        timeout = pod.spec.terminationGracePeriodSeconds * -timeout_grace
      end

      if (dur = Time.now - storage(pod).terminating_at) >= timeout

        logger.debug "Pod #{pod} is stuck in terminating (#{dur.to_duration}), marking for force delete"
        mark(pod, :force_delete)
      end
    end
  end
end
