require 'cassandra-orm/model/finder'

module CassandraORM
  class Model < Base
    module Persist
      def save **options
        new? ? _create(options) : _update(options)
      end

      def destroy
        hash = primary_key_hash
        keys, values = hash.keys, hash.values
        cql = cql_for_delete keys
        stmt = session.prepare cql
        session.execute stmt, arguments: values
        @errors.clear
        @persisted = nil
        true
      end

    private

      def _create options
        attrs = attributes
        exclusive = options.delete :exclusive
        cql = cql_for_insert attrs.keys, exclusive: exclusive
        stmt = session.prepare cql
        row = session.execute(stmt, options.merge(arguments: attrs.values)).first
        if !exclusive || row['[applied]']
          @errors.clear
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
        @errors.clear
        @persisted = true
        true
      end

      def cql_for_insert keys, exclusive: false
        cql = "INSERT INTO #{self.class.table_name}" <<
              "(#{keys.join(', ')}) VALUES(#{keys.map {'?'}.join(', ')})"
        cql << ' IF NOT EXISTS' if exclusive
        cql
      end

      def cql_for_update keys, primary_keys
        "UPDATE #{self.class.table_name}" <<
        " SET #{keys.map { |key| "#{key} = ?" }.join(', ')}" <<
        " WHERE " << primary_keys.map { |key| "#{key} = ?" }.join(' AND ')
      end

      def cql_for_delete primary_keys
        "DELETE FROM #{self.class.table_name}" <<
        " WHERE " << primary_keys.map { |key| "#{key} = ?" }.join(' AND ')
      end
    end
  end
end
