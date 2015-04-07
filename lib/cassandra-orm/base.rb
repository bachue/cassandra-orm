require 'cassandra'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/indifferent_access'

module CassandraORM
  class Base
    class_attribute :session, :cluster, :keyspace

    class << self
      def configure config
        config = config.with_indifferent_access
        self.keyspace = config.delete :keyspace
        fail 'keyspace is required' unless keyspace
        self.cluster = Cassandra.cluster config
      end

      def connect
        fail 'Configure CassandraORM first' unless cluster
        self.session = cluster.connect keyspace
      end
    end
  end
end
