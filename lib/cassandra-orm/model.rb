require 'cassandra-orm/base'
require 'cassandra-orm/logger'
require 'cassandra-orm/model/finder'
require 'cassandra-orm/model/persist'
require 'cassandra-orm/model/errors'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/aliasing'

module CassandraORM
  class Model < Base
    extend Finder
    include Persist
    include Logger

    attr_reader :errors

    def initialize attrs = {}
      fail 'Cannot instantiate CassandraORM::Model' if self == Model
      set attrs
      @errors = Errors.new self
    end

    def set attrs
      attrs.each do |k, v|
        method = :"#{k}="
        respond_to?(method) ? send(method, v) : instance_variable_set(:"@#{k}", v)
      end
    end

    def attributes
      self.class.attributes.each_with_object({}) do |key, hash|
        hash[key] = send key
      end
    end

    def attributes= attrs
      attrs = attrs.symbolize_keys
      self.class.attributes.each do |attr|
        send "#{attr}=", attrs[attr]
      end
    end

    def primary_key_hash
      self.class.primary_key.each_with_object({}) do |key, hash|
        hash[key] = send key
      end
    end

    def inspect
      attrs = attributes.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')
      "#<#{self.class.name} #{attrs}>"
    end

    def new?
      !@persisted
    end

    def == right
      self.class == right.class &&
      primary_key_hash == right.primary_key_hash
    end

    def append_error key, value, options = {}
      @errors.append key, value, options
      false
    end

    def append_error! key, value, options = {}
      append_error key, value, options
      fail ValidationError
    end

    def reload
      hash = primary_key_hash
      keys, values = hash.keys, hash.values
      row = self.class.send(:_find_all, keys, values, limit: 1).first
      if row
        self.attributes = row
        @errors.clear
        @persisted = true
        self
      else
        @errors.clear
        @persisted = nil
        false
      end
    end

    class << self
      def inherited base
        base.singleton_class.class_exec do
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

          attr_reader :primary_key
          def set_primary_key *keys
            keys.uniq!
            attributes(*keys)
            keys.each { |key|
              define_method("#{key}_with_primary_key_check=") { |val|
                if new?
                  send("#{key}_without_primary_key_check=", val)
                elsif send(key) != val
                  fail(CannotUpdatePrimaryKey)
                end
              }
              alias_method_chain "#{key}=", :primary_key_check
            }
            @primary_key = keys.map(&:to_sym)
          end
          private :set_primary_key

          def table_name
            name.tableize
          end

          def truncate
            execute 'truncate', "TRUNCATE #{table_name}"
          end
        end
      end
    end
  end
end
