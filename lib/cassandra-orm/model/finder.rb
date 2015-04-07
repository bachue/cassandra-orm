require 'active_support/core_ext/hash/keys'
require 'cassandra-orm/error'

module CassandraORM
  class Model < Base
    module Finder
      def find_all attrs = {}, options = {}
        attrs = attrs.symbolize_keys
        invalid = attrs.keys - attributes
        fail InvalidAttributeError, "Attribute #{invalid.first} is invalid" unless invalid.empty?
        keys = attributes & attrs.keys
        values = keys.map { |key| attrs[key] }
        limit = options.delete :limit
        cql = cql_for_select table_name, keys, limit: limit
        stmt = session.prepare cql
        rows = session.execute stmt, options.merge(arguments: values)
        rows.map { |row| new row }
      end

      def find attrs, options = {}
        find_all(attrs, options.merge(limit: 1)).first
      end

    private

      def cql_for_select table_name, keys, limit: nil
        cql = "SELECT * FROM #{table_name}"
        cql << " WHERE #{keys.map { |key| "#{key} = ?" }.join(' AND ')}" unless keys.empty?
        cql << " LIMIT #{limit}" if limit
        cql
      end
    end
  end
end
