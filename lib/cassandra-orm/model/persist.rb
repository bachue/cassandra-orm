require 'cassandra-orm/model/finder'

module CassandraORM
  class Model < Base
    module Persist
      def save **options
        new? || options[:exclusive] ? _create(options) : _update(options)
      end

      def destroy **options
        hash = primary_key_hash
        keys, values = hash.keys, hash.values
        conditions = options.delete(:if) || {}
        cql = cql_for_delete keys, conditions.keys
        stmt = session.prepare cql
        row = session.execute(stmt, arguments:(values + conditions.values)).first
        if conditions.empty? || row['[applied]']
          @errors.clear
          @persisted = nil
          true
        else
          append_error :'[failed]', :conditions
        end
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
          append_error :'[failed]', :unique
        end
      end

      def _update options
        attrs = attributes
        keys = self.class.attributes - self.class.primary_key
        values = keys.map { |key| attrs[key] }
        primary_key_values = self.class.primary_key.map { |key| attrs[key] }
        conditions = options.delete(:if) || {}
        cql = cql_for_update keys, self.class.primary_key, conditions.keys
        stmt = session.prepare cql
        values += primary_key_values + conditions.values
        row = session.execute(stmt, options.merge(arguments: values)).first
        if conditions.empty? || row['[applied]']
          @errors.clear
          @persisted = true
          true
        else
          append_error :'[failed]', :conditions
        end
      end

      def cql_for_insert keys, exclusive: false
        cql = "INSERT INTO #{self.class.table_name}" <<
              "(#{keys.join(', ')}) VALUES(#{keys.map {'?'}.join(', ')})"
        cql << ' IF NOT EXISTS' if exclusive
        cql
      end

      def cql_for_update keys, primary_keys, conditions
        cql = "UPDATE #{self.class.table_name}" <<
              " SET #{keys.map { |key| "#{key} = ?" }.join(', ')}" <<
              ' WHERE ' << primary_keys.map { |key| "#{key} = ?" }.join(' AND ')
        cql << ' IF ' << conditions.map { |key| "#{key} = ?" }.join(' AND ') unless conditions.empty?
        cql
      end

      def cql_for_delete primary_keys, conditions
        cql = "DELETE FROM #{self.class.table_name}" <<
              ' WHERE ' << primary_keys.map { |key| "#{key} = ?" }.join(' AND ')
        cql << ' IF ' << conditions.map { |key| "#{key} = ?" }.join(' AND ') unless conditions.empty?
        cql
      end
    end
  end
end
