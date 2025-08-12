# frozen_string_literal: true

class UpdateUsersForDevise < ActiveRecord::Migration[7.1]
  def change
    # Remove existing columns if they exist
    remove_column :users, :shopify_user_id, :bigint if column_exists?(:users, :shopify_user_id)
    remove_column :users, :shopify_domain, :string if column_exists?(:users, :shopify_domain)
    remove_column :users, :access_token, :string if column_exists?(:users, :access_token)
    remove_column :users, :scope, :string if column_exists?(:users, :scope)
    remove_column :users, :expires_at, :datetime if column_exists?(:users, :expires_at)

    # Add Devise columns if they don't exist
    add_column :users, :email, :string, null: false unless column_exists?(:users, :email)
    add_column :users, :encrypted_password, :string, null: false, default: '' unless column_exists?(:users, :encrypted_password)
    add_column :users, :reset_password_token, :string unless column_exists?(:users, :reset_password_token)
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)
    add_column :users, :remember_created_at, :datetime unless column_exists?(:users, :remember_created_at)

    # Add VoipAppz-specific columns
    add_column :users, :first_name, :string, null: false, default: ''
    add_column :users, :last_name, :string, null: false, default: ''
    add_column :users, :role, :string, default: 'member', null: false
    add_column :users, :active, :boolean, default: true, null: false
    add_reference :users, :organization, null: true, foreign_key: true

    # Add indexes
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role
    add_index :users, :active

    # Change default values for existing columns
    change_column_default :users, :first_name, from: nil, to: ''
    change_column_default :users, :last_name, from: nil, to: ''
  end
end