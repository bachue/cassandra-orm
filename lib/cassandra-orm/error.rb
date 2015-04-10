module CassandraORM
  class Error < RuntimeError; end
  class ValidationError < RuntimeError; end
  class CannotUpdatePrimaryKey < RuntimeError; end
  class RecordNotFound < RuntimeError; end
  class SaveFailure < RuntimeError; end
  class DestroyFailure < RuntimeError; end
end
