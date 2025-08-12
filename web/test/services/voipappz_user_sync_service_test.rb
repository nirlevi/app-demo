# frozen_string_literal: true

require "test_helper"

class VoipappzUserSyncServiceTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user_data = {
      user_id: 'voip_user_123',
      email: 'sync@voipappz.io',
      first_name: 'Sync',
      last_name: 'User',
      role: 'admin',
      organization_id: 'voip_org_456',
      organization_name: 'VoipAppz Test Org',
      permissions: ['calls:read', 'calls:write', 'dashboard:read'],
      active: true
    }
  end

  test "should create new user from VoipAppz data" do
    assert_difference('User.count', 1) do
      user = VoipappzUserSyncService.sync_user(user_data: @user_data)
      
      assert_equal @user_data[:user_id], user.voipappz_user_id
      assert_equal @user_data[:email], user.email
      assert_equal @user_data[:first_name], user.first_name
      assert_equal @user_data[:last_name], user.last_name
      assert_equal @user_data[:role], user.role
      assert_equal @user_data[:permissions], user.permissions
      assert user.active?
    end
  end

  test "should create organization when creating new user" do
    assert_difference(['User.count', 'Organization.count'], 1) do
      user = VoipappzUserSyncService.sync_user(user_data: @user_data)
      
      assert_not_nil user.organization
      assert_equal @user_data[:organization_name], user.organization.name
      assert_equal @user_data[:organization_id], user.organization.voipappz_organization_id
    end
  end

  test "should update existing user" do
    # Create existing user
    existing_user = User.create!(
      voipappz_user_id: @user_data[:user_id],
      email: 'old@email.com',
      first_name: 'Old',
      last_name: 'Name',
      role: 'user',
      organization: @organization
    )
    
    assert_no_difference('User.count') do
      updated_user = VoipappzUserSyncService.sync_user(
        user: existing_user,
        user_data: @user_data
      )
      
      assert_equal existing_user.id, updated_user.id
      assert_equal @user_data[:email], updated_user.email
      assert_equal @user_data[:first_name], updated_user.first_name
      assert_equal @user_data[:role], updated_user.role
    end
  end

  test "should find existing user by VoipAppz ID and update" do
    # Create existing user
    existing_user = User.create!(
      voipappz_user_id: @user_data[:user_id],
      email: 'old@email.com',
      first_name: 'Old',
      last_name: 'Name',
      role: 'user',
      organization: @organization
    )
    
    # Sync without passing user object (should find by voipappz_user_id)
    updated_user = VoipappzUserSyncService.sync_user(user_data: @user_data)
    
    assert_equal existing_user.id, updated_user.id
    assert_equal @user_data[:email], updated_user.email
  end

  test "should update voipappz_metadata on sync" do
    user = VoipappzUserSyncService.sync_user(user_data: @user_data)
    
    metadata = user.voipappz_metadata
    assert_not_nil metadata['last_sync_at']
    assert_equal @user_data[:organization_id], metadata['organization_id']
    assert_equal @user_data[:organization_name], metadata['organization_name']
  end

  test "should batch sync multiple users" do
    users_data = [
      @user_data,
      @user_data.merge(
        user_id: 'voip_user_456',
        email: 'batch@voipappz.io',
        first_name: 'Batch',
        role: 'agent'
      )
    ]
    
    assert_difference('User.count', 2) do
      users = VoipappzUserSyncService.batch_sync(
        users_data: users_data,
        organization: @organization
      )
      
      assert_equal 2, users.count
      assert_equal 'sync@voipappz.io', users.first.email
      assert_equal 'batch@voipappz.io', users.second.email
    end
  end

  test "should handle organization consistency validation" do
    different_org = Organization.create!(
      name: 'Different Org',
      slug: 'different-org',
      plan: 'free'
    )
    
    existing_user = User.create!(
      voipappz_user_id: @user_data[:user_id],
      email: 'test@email.com',
      first_name: 'Test',
      last_name: 'User',
      role: 'user',
      organization: different_org
    )
    
    assert_raises(VoipappzUserSyncService::OrganizationMismatchError) do
      VoipappzUserSyncService.sync_user(
        user: existing_user,
        user_data: @user_data,
        organization: @organization  # Different from user's org
      )
    end
  end

  test "should determine organization plan based on user role" do
    owner_data = @user_data.merge(role: 'owner')
    user = VoipappzUserSyncService.sync_user(user_data: owner_data)
    
    assert_equal 'premium', user.organization.plan
  end

  test "should handle user deactivation" do
    active_user = User.create!(
      voipappz_user_id: @user_data[:user_id],
      email: 'active@email.com',
      first_name: 'Active',
      last_name: 'User',
      role: 'user',
      active: true
    )
    
    deactivated_data = @user_data.merge(active: false)
    
    updated_user = VoipappzUserSyncService.sync_user(
      user: active_user,
      user_data: deactivated_data
    )
    
    assert_not updated_user.active?
  end

  test "should handle missing organization data gracefully" do
    user_data_without_org = @user_data.except(:organization_id, :organization_name)
    
    user = VoipappzUserSyncService.sync_user(user_data: user_data_without_org)
    
    assert_nil user.organization
    assert_equal @user_data[:email], user.email
  end

  test "should validate required user data" do
    invalid_data = @user_data.except(:email)
    
    assert_raises(VoipappzUserSyncService::SyncError) do
      VoipappzUserSyncService.sync_user(user_data: invalid_data)
    end
  end

  test "should handle database validation errors" do
    # Try to create user with duplicate email
    User.create!(
      voipappz_user_id: 'existing_user',
      email: @user_data[:email],  # Same email
      first_name: 'Existing',
      last_name: 'User',
      role: 'user'
    )
    
    assert_raises(VoipappzUserSyncService::SyncError) do
      VoipappzUserSyncService.sync_user(user_data: @user_data)
    end
  end

  test "should sync user with existing organization" do
    # Create organization with matching VoipAppz ID
    existing_org = Organization.create!(
      name: 'Existing Org',
      slug: 'existing-org',
      plan: 'basic',
      voipappz_organization_id: @user_data[:organization_id]
    )
    
    user = VoipappzUserSyncService.sync_user(user_data: @user_data)
    
    # Should use existing organization, not create new one
    assert_equal existing_org.id, user.organization.id
    assert_equal existing_org.name, user.organization.name
  end

  test "should update organization association when user org changes" do
    # Create user with one organization
    old_org = Organization.create!(
      name: 'Old Org',
      slug: 'old-org',
      plan: 'free',
      voipappz_organization_id: 'old_org_id'
    )
    
    user = User.create!(
      voipappz_user_id: @user_data[:user_id],
      email: 'test@email.com',
      first_name: 'Test',
      last_name: 'User',
      role: 'user',
      organization: old_org
    )
    
    # Sync with new organization data
    updated_user = VoipappzUserSyncService.sync_user(
      user: user,
      user_data: @user_data
    )
    
    # Should be associated with new organization
    assert_not_equal old_org.id, updated_user.organization.id
    assert_equal @user_data[:organization_name], updated_user.organization.name
  end
end