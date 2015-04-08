require 'cassandra-orm/model/finder'

module CassandraORM
  class Model < Base
    module Persist
      def save **options
        attrs = attributes
        if new?
          keys, values = attrs.keys, attrs.values
          cql = cql_for_insert keys
          stmt = session.prepare cql
          rows = session.execute stmt, options.merge(arguments: values)
          row = rows.first
          if row['[applied]']
            @persisted = true
            true
          else
            primary_key = self.class.primary_key
            append_error (primary_key.size == 1 ? primary_key.first : primary_key), :unique
          end
        else
          fail NotImplementedError
        end
      end

    private

      def cql_for_insert keys
        "INSERT INTO #{self.class.table_name}" <<
        "(#{keys.join(', ')}) VALUES(#{keys.map {'?'}.join(', ')}) IF NOT EXISTS"
      end
      end
    end
  end
end
