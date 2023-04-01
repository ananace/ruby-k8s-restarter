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
        doc = Psych.load(File.read(file))

        handlers = doc['handlers'].map do |handler, data|
          unless data.fetch('enabled', false)
            logger.info "Handler #{handler} not enabled, skipping."
            next
          end

          unless K8sRestarter::Handlers.const_defined? handler.to_sym
            logger.info "Handler #{handler} is unknown, skipping."
            next
          end

          klass = K8sRestarter::Handlers.const_get(handler.to_sym)
          args = (data['params'] || {}).transform_keys(&:to_sym)

          klass.new(**args)
        end

        new handlers: handlers
      end

      private

      def logger
        Logging.logger[self]
      end
    end

    attr_reader :handlers, :interval, :noop

    def initialize(handlers: [])
      @handlers = handlers
      @interval = 60
      @noop = true
    end
  end
end
