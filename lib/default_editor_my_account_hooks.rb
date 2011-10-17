#
# Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc
#
class DefaultEditorMyAccountHooks < Redmine::Hook::ViewListener

  include ApplicationHelper
  
  def view_my_account(context = {})
    if Setting.text_formatting == 'textile wysiwyg'
      user = context[:user]
      f = context[:form]
      return '' unless user
      editors = ['wysiwyg','textile']
      o = ''
      o << '</div><div class="box tabular"><p>'
      o << "<label>#{l(:label_editor)}</label>"
      o << select_tag("pref[editor]", options_for_select([[l(:label_wysiwyg_editor),DefaultEditorUserSetting::WYSIWYG_EDITOR],
        [l(:label_textile_editor),DefaultEditorUserSetting::TEXTILE_EDITOR]], user.preference.editor))
      o << '</p>'
      return o
    else
      return ''
    end
	
  end
  
end
