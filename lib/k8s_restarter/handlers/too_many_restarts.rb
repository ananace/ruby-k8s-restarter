# frozen_string_literal: true

module K8sRestarter::Handlers
  class TooManyRestarts < K8sRestarter::Handler
    parameter :action, Symbol, :evict, validate: ->(inp) { %i[delete evict].include?(inp) }
    parameter :also_daemonsets, :bool, false
    parameter :count, Numeric, 1000

    def applicable?(pod)
      return false if pod.phase == :pending
      return false if pod.metadata.deletionTimestamp
      return false if !also_daemonsets && pod.metadata.ownerReferences&.any? { |ref| ref.apiVersion == 'apps/v1' && ref.kind == 'DaemonSet' }

      restart_count = pod.status.containerStatuses&.sum(&:restartCount) || 0
      return false if restart_count < count

      super
    end

    def update(pod)
      logger.info "Pod #{pod} has more than #{count} restarts, marking"
      mark(pod, action)
    end
  end
end
