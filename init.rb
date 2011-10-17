#
# Redmine Wysiwyg Textile Editor
#
# P.J.Lawrence October 2010
#
# Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc
#
require 'redmine'
require 'default_editor_my_account_hooks'
require 'default_editor_user_patch'
require 'hpricot'
require 'undress/textile'

RAILS_DEFAULT_LOGGER.info 'Starting Wysiwyg Textile for Redmine'

Redmine::Plugin.register :redmine_wysiwyg_textile do
    name 'Redmine Wysiwyg Textile'
    author 'P.J. Lawrence and Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc'
    description 'A TinyMCE test application for Textile wiki pages'
    version '0.15'
    
    wiki_format_provider 'textile wysiwyg', RedmineWysiwygTextile::WikiFormatter, \
                                             RedmineWysiwygTextile::Helper
end








