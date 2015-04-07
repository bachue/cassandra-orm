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
        _find_all(keys, values, limit: limit, **options).map do |row|
          object = new row
          object.instance_variable_set :@new_record, false
          object
        end
      end

      def find attrs, options = {}
        find_all(attrs, options.merge(limit: 1)).first
      end

    private

      def _find_all keys, values, limit: nil, **options
        cql = cql_for_select keys, limit: limit
        stmt = session.prepare cql
        session.execute stmt, options.merge(arguments: values)
      end

      def cql_for_select keys, limit: nil
        cql = "SELECT * FROM #{table_name}"
        cql << " WHERE #{keys.map { |key| "#{key} = ?" }.join(' AND ')}" unless keys.empty?
        cql << " LIMIT #{limit}" if limit
        cql
      end
    end
  end
end
