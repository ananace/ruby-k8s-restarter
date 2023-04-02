# frozen_string_literal: true

require 'ostruct'

module K8sRestarter
  class Handler
    attr_accessor :client

    def initialize(**params)
      @marked = []

      params.each do |k, v|
        setter = :"#{k}="
        raise ArgumentError, "Unknown parameter #{k}" unless respond_to? setter

        send(setter, v)
      end
    end

    def logger
      Logging.logger[self]
    end

    def key
      self.class.name.underscore.to_sym
    end

    def update
      raise NotImplementedError
    end

    def parameters
      self.class.parameters.to_h { |k, _v| [k, send(k)] }
    end

    def applicable?(pod)
      return true if label_selector.empty?

      label_selector.each do |key, value|
        return false if pod.metadata.labels[key] != value
      end

      true
    end

    def act!(noop: false)
      @marked.each do |pod, action|
        if noop
          logger.debug "For #{pod}, would have applied action #{action.to_s.gsub '_', ' '}, but skipping due to no-op."
          next
        end

        logger.debug "#{"#{action.to_s.gsub('_', ' ').capitalize.delete_suffix('e')}ing"} #{pod}."

        case action
        when :evict
          apiversion = client.k8s_version?('>= 1.22') ? 'policy/v1' : 'policy/v1beta1'

          obj = K8s::Resource.new(
            apiVersion: apiversion,
            kind: 'Eviction',
            metadata: {
              namespace: pod.namespace,
              name: pod.name
            }
          )

          client
            .k8s_client
            .api(apiversion)
            .resource('eviction')
            .create(obj)
        when :delete
          pod.delete
        when :force_delete
          pod.delete!
        end

      rescue StandardError => e
        logger.error "  Failed! #{e.class}: #{e}\n    #{e.backtrace[0..10].join("\n    ")}"
      end

      @marked = []
    end

    class << self
      def parameters
        if superclass.respond_to? :parameters
          superclass.parameters.merge @parameters
        else
          @parameters
        end
      end

      def desc(description)
        @param_desc = description
      end

      def parameter(name, type, value = nil, **_)
        raise ArgumentError, "#{type.inspect} is not a valid type" unless type == :bool || type.is_a?(Class)

        name = name.to_s.to_sym unless name.is_a? Symbol

        @parameters ||= {}
        param = { name: name, type: type, default: value }
        param[:desc] = @param_desc if @param_desc
        @param_desc = nil
        @parameters[name] = param

        if type == :bool
          type1 = TrueClass
          type2 = FalseClass
        else
          type1 = type
          type2 = type
        end

        if value.nil?
          class_eval <<~CODE, __FILE__, __LINE__ + 1
            private

            def #{name}_default
              nil
            end
          CODE
        else
          class_eval <<~CODE, __FILE__, __LINE__ + 1
            private

            def #{name}_default
              val = self.class.parameters.dig(#{name.inspect}, :default)
              return val.call if val.is_a? Proc

              val
            end
          CODE
        end

        class_eval <<~CODE, __FILE__, __LINE__ + 1
          def #{name}
            @parameters ||= {}
            @parameters.fetch(#{name.inspect}, #{name}_default)
          end

          def #{name}=(input)
            #{type == String ? 'input = input.to_s if !input.is_a? String' : nil}
            #{type == Symbol ? 'input = input.to_s.delete_prefix(":").to_sym if !input.is_a? Symbol' : nil}
            #{[Numeric, Float].include? type ? 'input = input.to_s.to_f if !input.is_a?(Numeric) && input.to_s =~ /^-?\d+(\.\d+)?$/' : nil}
            #{type == Integer ? 'input = input.to_s.to_i if !input.is_a?(Integer) && input.to_s =~ /^-?\d+(\.\d+)?$/' : nil}
            #{type == :bool ? 'input = input.to_s =~ /^t(rue)?|y(es)?|1$/i if !input.is_a?(TrueClass) && !input.is_a?(FalseClass)' : nil}

            raise ArgumentError, "\#{input.inspect} is not a #{type}" unless input.is_a?(#{type1}) || input.is_a?(#{type2})

            @parameters ||= {}
            @parameters[#{name.inspect}] = input
          end
        CODE
      end
    end

    desc <<~DOC
      Filter the acceptable pods by a given label selector (key=value)
    DOC
    parameter :label_selector, Hash, {}

    protected

    def mark(pod, action)
      @marked << [pod, action]
    end

    def unmark(pod)
      @marked.delete_if { |marked, _| marked == pod }
    end

    def storage(pod)
      pod.storage[key] ||= OpenStruct.new.tap do |struct| # rubocop:disable Style/OpenStructUse
        struct._pod = pod
        struct._key = key

        struct.instance_eval do
          def delete!
            _pod.storage.delete _key
            nil
          end
        end
      end
    end
  end
end
