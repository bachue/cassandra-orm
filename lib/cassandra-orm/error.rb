module CassandraORM
  class Error < RuntimeError; end
  class CannotUpdatePrimaryKey < RuntimeError; end
end
