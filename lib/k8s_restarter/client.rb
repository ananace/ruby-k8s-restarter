# frozen_string_literal: true

module K8sRestarter
  # Handler client
  class Client
    attr_accessor :noop

    def initialize
      @k8s_client = nil
      @handlers = []
      @pods = []
      @noop = false
    end

    def logger
      Logging.logger[self]
    end

    def add_handler(handler, **args)
      logger.debug "Adding handler #{handler.inspect}"

      if handler.is_a? Class
        pre_handler = handler
        handler = K8sRestarter::Handlers.const_get(handler.to_s.to_sym) rescue nil
        handler ||= K8sRestarter::Handlers.const_get(handler.to_s.camelcase.to_sym) rescue nil
        raise ArgumentError, "Unknown handler #{pre_handler}" unless handler
      end

      if handler.is_a? Class
        handler = handler.new(**args)
      elsif handler.is_a? Handler
        args.each do |k, v|
          handler.public_send :"#{k}=", v
        end
      else
        raise ArgumentError, "Handler must be a Handler instance, not #{handler.class}"
      end

      handler.client = self
      @handlers << handler
      handler
    end

    def update
      logger.debug 'Retrieving updated pod list...'

      pods do |pod|
        @handlers.each do |handler|
          next unless handler.applicable? pod

          logger.debug "Applying handler #{handler.class} to #{pod}..."

          handler.update pod
        end
      end

      logger.debug 'Applying any queued actions...'

      @handlers.each do |h|
        h.act! noop: @noop
      end
    end

    def k8s_client
      @k8s_client ||= K8s::Client.autoconfig
    end

    def k8s_version
      @k8s_version ||= k8s_client.version.then do |ver|
        "#{ver.major}.#{ver.minor}"
      end
    end

    def k8s_version?(other_version)
      Gem::Dependency.new('', other_version).match?('', k8s_version)
    end

    private

    def pods(&block)
      keep = Set.new

      k8s_client.api('v1').resource('pods').list.each do |podspec|
        pod = Pod.new(
          podspec.metadata.namespace,
          podspec.metadata.name,
          client: self,
          data: podspec
        )
        keep << pod.uuid

        stored = @pods.find { |existing| existing.uuid == pod.uuid }
        if stored
          stored.refresh!(pod)
        else
          @pods << pod
          stored = pod
        end

        block.call stored

        stored.clear!
      end

      @pods.delete_if { |pod| !keep.include? pod.uuid }
    end
  end
end
