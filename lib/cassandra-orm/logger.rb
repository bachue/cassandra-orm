require 'active_support/benchmarkable'

module CassandraORM
  module Logger
    include ActiveSupport::Benchmarkable

    def self.included base
      base.extend self
      base.singleton_class.class_exec do
        def logger
          @logger ||= cluster.instance_variable_get :@logger
        end
        private :logger

        def execute identifier, statement, options = {}
          debug identifier, _fetch_cql(statement).strip, options[:arguments] do
            session.execute statement, options
          end
        end

        def _fetch_cql statement
          case statement
          when String, Cassandra::Statements::Simple then statement
          when Cassandra::Statements::Prepared, Cassandra::Statements::Bound then statement.cql
          when Cassandra::Statements::Batch then "[#{statement.statements.join('; ')}]"
          else statement.inspect
          end
        end
        private :_fetch_cql
      end
    end

    def execute identifier, cql, options = {}
      self.class.execute identifier, cql, options
    end

    def debug identifier, cql, values, &block
      message = "CQL [#{identifier}] #{cql}"
      message << " % #{values.inspect}" if values
      benchmark message, &block
    end
    private :debug

    def logger
      self.class.send :logger
    end
    private :logger
  end
end
