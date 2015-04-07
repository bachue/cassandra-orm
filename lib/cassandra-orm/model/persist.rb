require 'cassandra-orm/model/finder'

module CassandraORM
  class Model < Base
    module Persist
      def save reload: false, **options
        attrs = attributes
        keys, values = attrs.keys, attrs.values
        if new?
          cql = cql_for_insert keys, values
          stmt = session.prepare cql
          rows = session.execute stmt, options.merge(arguments: values)
          row = rows.first
          if row['[applied]']
            @new_record = false
            if reload
              hash = primary_key_hash
              self.attributes = self.class.send(:_find_all, hash.keys, hash.values).first
              true
            else
              true
            end
          else
            primary_key = self.class.primary_key
            append_error (primary_key.size == 1 ? primary_key.first : primary_key), :unique
          end
        else
          fail NotImplementedError
        end
      end

    private

      def cql_for_insert keys, values
        cql = "INSERT INTO #{self.class.table_name}"
        cql << "(#{keys.join(', ')}) VALUES(#{keys.map {'?'}.join(', ')}) IF NOT EXISTS"
        cql
      end
    end
  end
end
