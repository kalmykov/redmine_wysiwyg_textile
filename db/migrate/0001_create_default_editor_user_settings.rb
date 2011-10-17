#
# Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc
#
class CreateDefaultEditorUserSettings < ActiveRecord::Migration
  def self.up
    create_table :default_editor_user_settings do |t|
      t.column :user_id, :integer
      t.column :editor, :string, :default => "__textile__"
      t.column :updated_at, :timestamp
    end
  end
  
  def self.down
    drop_table :default_editor_user_settings
  end
  
end