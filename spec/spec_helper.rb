require 'bundler'
require 'bundler/setup'
require 'erb'
require 'yaml'
require 'pathname'
require 'active_support/core_ext/class/subclasses'
require 'active_support/core_ext/module/introspection'

if ENV['CI']
  Bundler.require :default
else
  Bundler.require :default, :debug
end

path = Pathname File.expand_path 'cassandra.yml', __dir__
if path.exist?
  CASSANDRA_CONFIG = YAML.load(ERB.new(path.read).result)
else
  CASSANDRA_CONFIG = {keyspace: 'test', logger: Logger.new('/tmp/cassandra_orm.log')}
end

require_relative '../lib/cassandra-orm'

RSpec.configure do |config|
  config.before :each do
    begin
      CassandraORM.configure CASSANDRA_CONFIG.merge keyspace: 'system'
      CassandraORM.connect
      CassandraORM.execute 'initialize', <<-CQL
        CREATE KEYSPACE #{CASSANDRA_CONFIG[:keyspace]}
        WITH replication = {
          'class': 'SimpleStrategy',
          'replication_factor': 1
        }
      CQL
      CassandraORM.configure CASSANDRA_CONFIG
      CassandraORM.connect
      CassandraORM.execute 'initialize', <<-CQL
        CREATE TABLE products(name TEXT PRIMARY KEY)
      CQL
      CassandraORM.execute 'initialize', <<-CQL
        CREATE TABLE upgrades(
          product_name TEXT,
          version bigint,
          minimal_version bigint,
          url TEXT,
          changelog TEXT,
          PRIMARY KEY (product_name, version)
        )
      CQL
    rescue Cassandra::Errors::AlreadyExistsError
      CassandraORM.execute 'clear', <<-CQL
        DROP KEYSPACE #{CASSANDRA_CONFIG[:keyspace]}
      CQL
      retry
    end
  end

  config.after :each do
    CassandraORM::Model.subclasses.each do |mod|
      mod.parent.send :remove_const, mod.name.split('::').last rescue nil
    end
    CassandraORM.configure CASSANDRA_CONFIG.merge keyspace: 'system'
    CassandraORM.connect
    CassandraORM.execute 'clear', <<-CQL
      DROP KEYSPACE #{CASSANDRA_CONFIG[:keyspace]}
    CQL
  end
end
