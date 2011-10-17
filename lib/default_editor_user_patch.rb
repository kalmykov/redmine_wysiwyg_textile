#
# Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc
#
class UserPreference < ActiveRecord::Base

  def editor
    editor_setting = DefaultEditorUserSetting.find_editor_by_user_id(user.id)
    return nil unless editor_setting
    editor_setting.editor
  end

  def editor=(name)
    editor_setting = DefaultEditorUserSetting.find_or_create_editor_by_user_id(user.id)
    editor_setting.editor = name
    editor_setting.save!
  end
  
end
