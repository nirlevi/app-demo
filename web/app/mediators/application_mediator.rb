# frozen_string_literal: true

# ApplicationMediator provides the foundation for the mediator pattern
# following Pliny conventions for orchestrating business logic
class ApplicationMediator
  class << self
    # Pliny-style class method for running mediators
    # @param options [Hash] options to pass to the mediator
    # @return [Object] result from the mediator's call method
    def run(options = {})
      new(options).call
    end
  end

  # @param options [Hash] initialization options
  def initialize(options = {})
    @options = options
  end

  # Abstract method to be implemented by subclasses
  # @raise [NotImplementedError] if not implemented by subclass
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  attr_reader :options

  # Execute a service with error handling
  # @param service_class [Class] the service class to execute
  # @param args [Array] arguments to pass to service
  # @param kwargs [Hash] keyword arguments to pass to service
  # @return [Object] result from service execution
  def execute_service(service_class, *args, **kwargs)
    service_class.call(*args, **kwargs)
  rescue StandardError => e
    Rails.logger.error("Service execution failed: #{service_class} - #{e.message}")
    raise
  end

  # Execute VoipAppz API calls with consistent error handling
  # This will be the foundation for your VoipAppz platform integration
  # @param client_method [Symbol] method to call on VoipAppz client
  # @param args [Array] arguments to pass to client method
  # @return [Object] result from API call
  def execute_voipappz_api(client_method, *args)
    client = voipappz_client
    result = client.send(client_method, *args)
    Rails.logger.debug("VoipAppz API call successful: #{client_method}")
    result
  rescue VoipappzClient::APIError => e
    Rails.logger.error("VoipAppz API call failed: #{client_method} - #{e.message}")
    
    # For now, return nil to allow graceful degradation
    # TODO: Implement proper error handling strategy
    nil
  end

  # VoipAppz client instance with organization authentication
  # TODO: Add organization.voipappz_token field to organization model
  def voipappz_client
    @voipappz_client ||= VoipappzClient.new(
      organization_token: organization_token,
      user_token: user_token
    )
  end

  # Organization token for VoipAppz API authentication
  # TODO: Add voipappz_token column to organizations table
  def organization_token
    # Placeholder - will need to be stored in organization record
    ENV['VOIPAPPZ_ORGANIZATION_TOKEN']
  end

  # User token for VoipAppz API authentication (when available)
  # TODO: Integrate with VoipAppz user authentication
  def user_token
    # Placeholder - will be provided by VoipAppz auth system
    nil
  end
end