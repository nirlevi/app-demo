class RemoveShopifyColumnsFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :shopify_token, :string
    remove_column :users, :access_scopes, :string
  end
end
