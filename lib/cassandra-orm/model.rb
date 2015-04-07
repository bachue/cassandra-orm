require 'cassandra-orm/base'

module CassandraORM
  class Model
    class << self
      def inherited base
        base.singleton_class.instance_exec do
          attr_reader :primary_key
        end
        base.instance_exec do
          def attributes *names
            @attributes ||= []
            if names.empty?
              @attributes
            else
              attr_accessor(*names)
              @attributes.concat names.map(&:to_sym)
            end
          end

          def set_primary_key *keys
            attributes(*keys)
            @primary_key = keys.map(&:to_sym)
          end
        end
      end
    end
  end
end
