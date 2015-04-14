require 'active_support/core_ext/hash/keys'
require 'cassandra-orm/error'
require 'cassandra-orm/async_wrapper'

module CassandraORM
  class Model < Base
    module Finder
      def find_all attrs = {}, options = {}
        attrs = attrs.symbolize_keys
        invalid = attrs.keys - attributes
        keys = (attributes & attrs.keys) + invalid
        values = keys.map { |key| attrs[key] }
        limit = options.delete :limit
        async = options[:async]
        result = _find_all(keys, values, limit: limit, **options)
        if async
          AsyncWrapper.new(result, :get) { |all| all.map(&method(:_fetch)) }
        else
          result.map(&method(:_fetch))
        end
      end

      def find attrs, options = {}
        all = find_all attrs, options.merge(limit: 1)
        options[:async] ? AsyncWrapper.new(all, :first) : all.first
      end

      def find! attrs, options = {}
        result = find attrs, options.except(:async)
        raise RecordNotFound unless result
        result
      end

      def all options = {}
        find_all({}, options)
      end

      def first options = {}
        find({}, options)
      end

      def count
        execute('count', "SELECT COUNT(*) FROM #{table_name}").first['count']
      end

    private

      def _fetch row
        new(row).tap { |model| model.instance_variable_set(:@persisted, true) }
      end

      def _find_all keys, values, limit: nil, **options
        cql = cql_for_select keys, limit: limit
        stmt = session.prepare cql
        async = options.delete :async
        if async
          execute_async 'find', stmt, options.merge(arguments: values)
        else
          execute 'find', stmt, options.merge(arguments: values)
        end
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
