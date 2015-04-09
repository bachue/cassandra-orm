require 'cassandra-orm/model'

module CassandraORM
  def configure config
    Base.configure config
  end

  def connect
    Base.connect
  end

  def execute identifier, cql, options = {}
    Model.execute identifier, cql, options
  end

  module_function :configure, :connect, :execute
end
