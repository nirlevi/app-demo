# frozen_string_literal: true

class EmailNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, notification_type, data = {})
    user = User.find_by(id: user_id)
    return unless user

    case notification_type
    when 'welcome'
      UserMailer.welcome_email(user).deliver_now
    when 'password_reset'
      UserMailer.password_reset_email(user, data[:reset_token]).deliver_now
    when 'organization_invite'
      UserMailer.organization_invite_email(user, data[:organization_id]).deliver_now
    else
      logger.warn("Unknown notification type: #{notification_type}")
    end
  rescue ActiveRecord::RecordNotFound
    logger.error("User not found: #{user_id}")
  rescue => e
    logger.error("Failed to send #{notification_type} email to user #{user_id}: #{e.message}")
    raise
  end
end