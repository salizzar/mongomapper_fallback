require 'mongo_mapper'
require 'mongomapper_fallback/version'

module MongomapperFallback
  def replicaset_safe_run!(logger, options = {})
    sig_quit = options[:sig_quit] === true

    retry_limit = options[:retry_limit].to_i
    retry_limit = 5 if retry_limit == 0

    attempts = 0
    replicaset_errors = [ Mongo::ConnectionFailure, Mongo::OperationFailure ]

    yield
  rescue *replicaset_errors => e
    error = e

    begin
      refresh!      if error.class == Mongo::ConnectionFailure
      reconnect!    if error.class == Mongo::OperationFailure
      quit_process! if sig_quit

      stop_retry = true
    rescue *replicaset_errors => ex
      logger.error("Failed to reconnect to MongoDB: [#{ex}]")

      attempts += 1
      error = ex
      raise(error) if attempts >= retry_limit

      retry
    end

    logger.info('Successfully reconnected to MongoDB. Retrying now.')

    retry
  end

  private

  def refresh!
    MongoMapper.connection.hard_refresh!
  end

  def reconnect!
    MongoMapper.connection.reconnect
  end

  def quit_process!
    Process.kill('QUIT', Process.ppid)
  end
end

