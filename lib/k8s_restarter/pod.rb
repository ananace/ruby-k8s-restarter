# frozen_string_literal: true

module K8sRestarter
  class Pod
    attr_reader :name, :namespace, :storage

    def initialize(namespace, name, client:, data: nil)
      @namespace = namespace
      @name = name
      @client = client

      @storage = {}
      @data = data
    end

    def namespace; metadata.namespace; end
    def name; metadata.name; end
    def uuid; metadata.uid; end

    def refresh!(data = nil)
      data = data.data if data.is_a? Pod

      @data = data
      #@node = node
    end
    
    def node
      client.k8s_client.api('v1').resource('nodes').get(data.spec.nodeName)
    end

    def phase
      status.phase.downcase.to_sym
    end

    def ready?
      status.conditions.find { |c| c.type == 'Ready' }&.status&.downcase == 'true'
    end

    def delete
      client.k8s_client.api('v1').resource('pods', namespace: namespace).delete(name)
    end

    def delete!
      # client.k8s_client.api('v1').resource('pods', namespace: namespace).delete(name, grace_period: 0)

      rc = client.k8s_client.api('v1').resource('pods', namespace: namespace)
      client.k8s_client.transport.request(
        method: 'DELETE',
        path: rc.path(name, namespace: namespace),
        query: rc.make_query(
          'gracePeriodSeconds' => 0,
          'propagationPolicy' => 'Background',
        ),
        response_class: rc.resource_class
      )
    end

    def reload!
      @data = nil
    end

    def metadata; @data.metadata; end
    def spec; @data.spec; end
    def status; @data.status; end

    def to_s
      "#{namespace}/#{name}"
    end

    private

    attr_reader :client

    def data
      @data ||= client.api('v1').resource('pods', namespace: namespace).get(name)
    end
  end
end
