require 'bundler'
require 'bundler/setup'
require 'erb'
require 'yaml'
require 'pathname'

if ENV['CI']
  Bundler.require :default
else
  Bundler.require :default, :debug
end

path = Pathname File.expand_path 'cassandra.yml', __dir__
if path.exist?
  CASSANDRA_CONFIG = YAML.load(ERB.new(path.read).result)
else
  CASSANDRA_CONFIG = {keyspace: 'test'}
end

require_relative '../lib/cassandra-orm'

RSpec.configure do |config|
  config.before :each do
    CassandraORM.configure CASSANDRA_CONFIG.merge keyspace: 'system'
    CassandraORM.connect
    CassandraORM.execute <<-CQL
      CREATE KEYSPACE #{CASSANDRA_CONFIG[:keyspace]}
      WITH replication = {
        'class': 'SimpleStrategy',
        'replication_factor': 1
      }
    CQL
    CassandraORM.configure CASSANDRA_CONFIG
    CassandraORM.connect
    CassandraORM.execute <<-CQL
      CREATE TABLE products(name TEXT PRIMARY KEY)
    CQL
    CassandraORM.execute <<-CQL
      CREATE TABLE upgrades(
        product_name TEXT,
        version frozen <tuple <bigint, bigint>>,
        minimal_version frozen <tuple <bigint, bigint>>,
        url TEXT,
        changelog TEXT,
        created_at TIMESTAMP,
        PRIMARY KEY (product_name, version)
      )
    CQL
  end

  config.after :each do
    CassandraORM.configure CASSANDRA_CONFIG.merge keyspace: 'system'
    CassandraORM.connect
    CassandraORM.execute <<-CQL
      DROP KEYSPACE #{CASSANDRA_CONFIG[:keyspace]}
    CQL
  end
end
