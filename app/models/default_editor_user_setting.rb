#
# Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc
#
class DefaultEditorUserSetting < ActiveRecord::Base
  unloadable
  belongs_to :user
  validates_presence_of :user
  
  WYSIWYG_EDITOR = '__wysiwyg__'
  TEXTILE_EDITOR = '__textile__'

  def self.find_editor_by_user_id(user_id)
    DefaultEditorUserSetting.find(:first, :conditions => ['user_id = ?', user_id])
  end
  
  def self.find_or_create_editor_by_user_id(user_id)
    editor = find_editor_by_user_id(user_id)
    unless editor
      editor = DefaultEditorUserSetting.new
      editor.user_id = user_id
      editor.editor = '__textile__'
    end
    return editor
  end

  def editor_name
    return '' if editor == WYSIWYG_EDITOR
    editor
  end
	
end
