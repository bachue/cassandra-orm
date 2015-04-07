require 'cassandra-orm/base'
require 'active_support/core_ext/hash/keys'

module CassandraORM
  class Model
    def initialize attrs = {}
      attrs = attrs.symbolize_keys
      keys = self.class.attributes & attrs.keys
      keys.each do |attr|
        send "#{attr}=", attrs[attr]
      end
    end

    def attributes
      self.class.attributes.each_with_object({}) do |key, hash|
        hash[key] = send key
      end
    end

    def primary_key_hash
      self.class.primary_key.each_with_object({}) do |key, hash|
        hash[key] = send key
      end
    end

    class << self
      def inherited base
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
        base.singleton_class.instance_exec do
          attr_reader :primary_key
          private :set_primary_key
        end
      end
    end
  end
end
