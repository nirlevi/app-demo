# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError
  
  # Log job execution details
  around_perform do |job, block|
    start_time = Time.current
    logger.info("Starting job: #{job.class.name} with arguments: #{job.arguments}")
    
    begin
      block.call
      duration = Time.current - start_time
      logger.info("Completed job: #{job.class.name} in #{duration.round(2)} seconds")
    rescue => e
      duration = Time.current - start_time
      logger.error("Failed job: #{job.class.name} after #{duration.round(2)} seconds - #{e.message}")
      raise
    end
  end
end