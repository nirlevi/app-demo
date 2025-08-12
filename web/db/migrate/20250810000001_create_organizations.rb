# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan, default: 'free', null: false
      t.boolean :active, default: true, null: false
      t.json :settings, default: {}

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
    add_index :organizations, :plan
    add_index :organizations, :active
  end
end