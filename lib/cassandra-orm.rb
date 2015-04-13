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

  def heartbeat
    Model.execute('heartbeat', 'SELECT NOW() FROM system.local').size == 1
  rescue
    false
  end

  module_function :configure, :connect, :execute, :heartbeat
end
