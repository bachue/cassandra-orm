require 'cassandra'
require 'active_support/core_ext/class/attribute'

module CassandraORM
  class Base
    class_attribute :session, :cluster, :keyspace, :config

    def initialize
      fail 'Cannot instantiate CassandraORM::Base' if self == Base
    end

    class << self
      def configure config
        self.config = config.symbolize_keys
        self.keyspace = self.config.delete :keyspace
        fail 'keyspace is required' unless keyspace
      end

      def connect
        fail 'Configure CassandraORM first' unless config
        self.cluster = Cassandra.cluster config.merge(page_size: nil)
        self.session = cluster.connect keyspace
      end

      def reconnect
        fail 'Connect to Cassandra first' unless session
        self.session.close_async
        self.cluster.close_async
        connect
      end
    end
  end
end
