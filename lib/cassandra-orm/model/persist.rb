require 'cassandra-orm/model/finder'

module CassandraORM
  class Model < Base
    module Persist
      def save **options
        new? ? _create(options) : _update(options)
      end

    private

      def _create options
        attrs = attributes
        keys, values = attrs.keys, attrs.values
        cql = cql_for_insert keys
        stmt = session.prepare cql
        rows = session.execute stmt, options.merge(arguments: values)
        row = rows.first
        if row['[applied]']
          @persisted = true
        else
          primary_key = self.class.primary_key
          append_error (primary_key.size == 1 ? primary_key.first : primary_key), :unique
        end
      end

      def _update options
        attrs = attributes
        keys = self.class.attributes - self.class.primary_key
        values = keys.map { |key| attrs[key] }
        primary_key_values = self.class.primary_key.map { |key| attrs[key] }
        cql = cql_for_update keys, self.class.primary_key
        stmt = session.prepare cql
        session.execute stmt, options.merge(arguments: values + primary_key_values)
        true
      end

      def cql_for_insert keys
        "INSERT INTO #{self.class.table_name}" <<
        "(#{keys.join(', ')}) VALUES(#{keys.map {'?'}.join(', ')}) IF NOT EXISTS"
      end

      def cql_for_update keys, primary_keys
        "UPDATE #{self.class.table_name}" <<
        " SET #{keys.map { |key| "#{key} = ?" }.join(', ')}" <<
        " WHERE " << primary_keys.map { |key| "#{key} = ?" }.join(' AND ')
      end
    end
  end
end
