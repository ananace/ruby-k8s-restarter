# frozen_string_literal: true

module K8sRestarter
  class Config
    class << self
      def load(file = 'config.yml')
        return load!(file) if File.exist? file

        logger.info 'No config file found, using defaults'

        new handlers: [K8sRestarter::Handlers::PodStuckTerminating.new]
      end

      def load!(file = 'config.yml')
        logger.info "Loading config from #{file}"

        doc = Psych.load(File.read(file))

        handlers = doc['handlers'].map do |handler, data|
          unless data.fetch('enabled', false)
            logger.debug "Handler #{handler} not enabled, skipping."
            next
          end

          unless K8sRestarter::Handlers.const_defined? handler.to_sym
            logger.info "Handler #{handler} is unknown, skipping."
            next
          end

          klass = K8sRestarter::Handlers.const_get(handler.to_sym)
          args = (data['params'] || {}).transform_keys(&:to_sym)

          klass.new(**args)
        end.compact

        new handlers: handlers, interval: doc['interval'] || 60, noop: doc['noop'] || false
      end

      private

      def logger
        Logging.logger[self]
      end
    end

    attr_reader :handlers, :interval, :noop

    def initialize(handlers: [], interval: 60, noop: false)
      @handlers = handlers
      @interval = interval
      @noop = noop
    end
  end
end
