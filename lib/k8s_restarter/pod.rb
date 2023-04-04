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

      uuid # Ensure uuid is stored
    end

    def uuid
      @uuid ||= metadata.uid
    end

    def refresh!(data = nil)
      data = data.send :data if data.is_a? Pod

      @data = data
    end

    def clear!
      @data = nil
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
          'propagationPolicy' => 'Background'
        ),
        response_class: rc.resource_class
      )
    end

    def evict
      apiversion = client.k8s_version?('>= 1.22') ? 'policy/v1' : 'policy/v1beta1'

      obj = K8s::Resource.new(
        apiVersion: apiversion,
        kind: 'Eviction',
        metadata: {
          namespace: namespace,
          name: name
        }
      )

      rc = client.k8s_client.api('v1').resource('pods/eviction', namespace: namespace)
      # rc.create_resource(obj)
      client.k8s_client.transport.request(
        method: 'POST',
        path: rc.path(name, namespace: namespace, subresource: 'eviction'),
        request_object: obj,
        response_class: rc.resource_class
      )
    end

    def reload!
      @data = nil
    end

    def metadata
      @data.metadata
    end

    def spec
      @data.spec
    end

    def status
      @data.status
    end

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
