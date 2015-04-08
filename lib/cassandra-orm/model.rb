require 'cassandra-orm/base'
require 'cassandra-orm/model/finder'
require 'cassandra-orm/model/persist'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/aliasing'

module CassandraORM
  class Model < Base
    extend Finder
    include Persist

    attr_reader :errors

    def initialize attrs = {}
      self.attributes = attrs
      @errors = {}
    end

    def attributes
      self.class.attributes.each_with_object({}) do |key, hash|
        hash[key] = send key
      end
    end

    def attributes= attrs
      attrs = attrs.symbolize_keys
      keys = self.class.attributes & attrs.keys
      keys.each do |attr|
        send "#{attr}=", attrs[attr]
      end
    end

    def primary_key_hash
      self.class.primary_key.each_with_object({}) do |key, hash|
        hash[key] = send key
      end
    end

    def new?
      !@persisted
    end

    def == right
      self.class == right.class &&
      primary_key_hash == right.primary_key_hash
    end

    def append_error key, value
      @errors.merge! key => value
      false
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
              @attributes.uniq!
            end
          end

          def set_primary_key *keys
            keys.uniq!
            attributes(*keys)
            keys.each { |key|
              define_method("#{key}_with_primary_key_check=") { |val|
                new? ? send("#{key}_without_primary_key_check=", val) : fail(CannotUpdatePrimaryKey)
              }
              alias_method_chain "#{key}=", :primary_key_check
            }
            @primary_key = keys.map(&:to_sym)
          end

          def table_name
            name.tableize
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
