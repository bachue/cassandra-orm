require 'cassandra-orm/model/finder'

module CassandraORM
  class Model < Base
    module Persist
      def save options = {}
        new? || options[:exclusive] ? _create(options) : _update(options)
      end

      def save! options = {}
        result = save options
        fail SaveFailure unless result
        result
      end

      def destroy options = {}
        @errors.clear
        return false if send_callback(:before_destroy) == false
        hash = primary_key_hash
        keys, values = hash.keys, hash.values
        conditions = options.delete(:if) || {}
        cql = cql_for_delete keys, conditions.keys
        stmt = session.prepare cql
        values += conditions.values
        row = execute('destroy', stmt, arguments: values).first
        if conditions.empty? || row['[applied]']
          @persisted = nil
          true
        else
          append_error :'[primarykey]', :conditions
        end
      end

      def destroy! options = {}
        result = destroy options
        fail DestroyFailure unless result
        result
      end

      # Callbacks
      %w(save destroy create update).each do |function|
        define_method(:"before_#{function}") { true }
        private :"before_#{function}"
      end

    private

      def send_callback callback
        send callback
      rescue ValidationError
        false
      end

      def _create options
        @errors.clear
        return false if send_callback(:before_create) == false
        return false if send_callback(:before_save) == false
        only = options.delete :only
        attrs = attributes
        attrs.slice!(*(Array(only).map(&:to_sym) + self.class.primary_key)) if only
        to_reload, exclusive = options.delete(:reload), options.delete(:exclusive)
        cql = cql_for_insert attrs.keys, exclusive: exclusive
        stmt = session.prepare cql
        row = execute('create', stmt, options.merge(arguments: attrs.values)).first
        if !exclusive || row['[applied]']
          @persisted = true
          to_reload ? reload : true
        else
          append_error :'[primarykey]', :unique
        end
      end

      def _update options
        @errors.clear
        return false if send_callback(:before_update) == false
        return false if send_callback(:before_save) == false
        only = options.delete :only
        attrs = attributes
        keys = self.class.attributes - self.class.primary_key
        keys &= Array(only).map(&:to_sym) if only
        values = keys.map { |key| attrs[key] }
        primary_key_values = self.class.primary_key.map { |key| attrs[key] }
        to_reload, conditions = options.delete(:reload), options.delete(:if) || {}
        cql = cql_for_update keys, self.class.primary_key, conditions.keys
        stmt = session.prepare cql
        values += primary_key_values + conditions.values
        row = execute('update', stmt, options.merge(arguments: values)).first
        if conditions.empty? || row['[applied]']
          @persisted = true
          to_reload ? reload : true
        else
          append_error :'[primarykey]', :conditions
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
