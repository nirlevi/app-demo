# frozen_string_literal: true

class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.text :description
      t.string :category, null: false
      t.string :status, default: 'active', null: false
      t.json :metadata, default: {}
      t.references :organization, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :items, :category
    add_index :items, :status
    add_index :items, [:organization_id, :category]
    add_index :items, [:organization_id, :status]
  end
end