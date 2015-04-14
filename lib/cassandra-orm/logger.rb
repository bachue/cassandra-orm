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

        def execute_async identifier, statement, options = {}
          logger.info log_message(identifier, _fetch_cql(statement).strip, options[:arguments])
          session.execute_async statement, options
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

    def execute_async identifier, cql, options = {}
      self.class.execute_async identifier, cql, options
    end

    def debug identifier, cql, values, &block
      benchmark log_message(identifier, cql, values), &block
    end
    private :debug

    def log_message identifier, cql, values
      message = "CQL [#{identifier}] #{cql}"
      message << " % #{values.inspect}" if values
      message
    end
    private :log_message

    def logger
      self.class.send :logger
    end
    private :logger
  end
end
