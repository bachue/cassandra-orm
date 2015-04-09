require 'cassandra'
require 'active_support/core_ext/class/attribute'

module CassandraORM
  class Base
    class_attribute :session, :cluster, :keyspace

    def initialize
      fail 'Cannot instantiate CassandraORM::Base' if self == Base
    end

    class << self
      def configure config
        config = config.symbolize_keys
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
