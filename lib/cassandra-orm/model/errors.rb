require 'i18n'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'

I18n.load_path.unshift File.expand_path('i18n/en.yml', __dir__)

module CassandraORM
  class Model < Base
    class Errors
      def initialize object
        @object = object
        @errors = Hash.new { |h, k| h[k] = {} }
      end

      delegate :inspect, :clear, :empty?, :==, :eql?, to: :@errors

      def append attr, key, options = {}
        @errors[attr].merge! key => options
      end

      def full_messages locale: :en
        @errors.map do |attr, errlist|
          errlist.map do |key, options|
            if attr.to_s =~ /\[(.+)\]/
              skey, name = $1, @object.class.name.underscore
              I18n.t key, options.merge(scope: [:cassandra, name, :errors, skey], locale: locale)
            else
              I18n.t key, options.merge(attr: attr, scope: [:cassandra, :errors], locale: locale)
            end
          end
        end.flatten
      end
    end
  end
end
