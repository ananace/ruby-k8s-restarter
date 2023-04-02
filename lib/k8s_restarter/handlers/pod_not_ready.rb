# frozen_string_literal: true

module K8sRestarter::Handlers
  class PodNotReady < K8sRestarter::Handler
    parameter :action, Symbol, :evict, validate: -> { |inp| %i[delete evict].include?(inp) }
    parameter :timeout, Numeric, 5 * 60

    def applicable?(pod)
      return false if pod.ready?

      super
    end

    def update(pod)
      raise NotImplementedError, 'Not implemented yet'

      if pod.ready?
        storage(pod).ready_at = Time.now
        return
      end

      last_ready = storage(pod).ready_at || Time.at(0)

      mark(pod, action) if Time.now - last_ready > 1 * 60
    end
  end
end
