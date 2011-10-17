require 'redcloth3'
require 'undress/textile'

# P.J.Lawrence October 2010
# Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc

class HTMLFormatter< RedCloth3
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::TextHelper
        include ActionView::Helpers::UrlHelper
        
        RULES = [:inline_wiki_link, :inline_external_wiki_link, :textile, :block_markdown_rule, :inline_auto_link, :inline_auto_mailto,
        :inline_document_link, :inline_version_link, :inline_revision_link, :inline_attachment_link,
        :smooth_offtags, :inline_issue_link]
        
        # Renders a link to wiki page 
        # such as
        # [[wikiPage]]
        # [[wikiPage|textToShow]]
        # [[wikiPageName#anchorOnWikiPage]]
        def inline_wiki_link(text)
          text.gsub!(/\[\[((\w|\s)+)((\||\#)((\w|\s)+))?\]\]/) do |m|
              wikiPage =$~[1]
              delimeter =$~[4]
              wikiPage2 =$~[5]
              # replace all spaces to '_' in wiki page name, and save name with spaces
              title = wikiPage.clone
              wikiPage.gsub!(/\s/, '_')
              # if there is wiki anchor, we should replace all spaces to '+' in anchor
              if(delimeter == "#")
                wikiPage2.gsub!(/\s/, '+')
              end
              # Class localWiki means that this wiki page belongs to current project.
              # Class mceNonEditable means that this line should be uneditable in TinyMCE WYSIWYG editor(noneditable plugin).
              if(delimeter.nil?)
                "\<span class=mceNonEditable\>" + "<a class=\"localWiki\" href=\"#{@serverUrl}\/#{@projectName}\/wiki\/#{wikiPage}\">#{title}</a>" + "\<\/span\>"
              elsif(!delimeter.nil? && delimeter == "#" && !wikiPage2.nil?)
                "\<span class=mceNonEditable\>" + "<a class=\"localWiki\" href=\"\/projects\/#{@projectName}\/wiki\/#{wikiPage}##{wikiPage2}\">#{title}</a>" + "\<\/span\>"
              elsif(!delimeter.nil? && delimeter == "|" && !wikiPage2.nil?)
                "\<span class=mceNonEditable\>" + "<a class=\"localWiki\" href=\"/\projects\/#{@projectName}\/wiki\/#{wikiPage}\">#{wikiPage2}</a>" + "\<\/span\>"
              end
          end
        end
        
        # Renders a wiki link to another project wiki
        # such as
        # [[projectName:wikiPage]]
        def inline_external_wiki_link(text)
          text.gsub!(/\[\[((\w|\s)+)\:((\w|\s)+)\]\]/) do |m|
            externalProjectName = $~[1]
            wikiPage = $~[3]
            # replace all spaces to '_' in wiki page name, and save name with spaces
            title = wikiPage.clone
            wikiPage.gsub!(/\s/, '_')
            # Getting project identifier from project name
            # But we can also put a project identifier in wiki link instead of real name of project
            @projects = Project.find(:all)
            @projects.each{|project| 
              if (project.name == externalProjectName || project.identifier == externalProjectName)
                @projectIdentifier = project.identifier.clone
              end
            }
            # Class externalWiki means that this wiki page belongs to other project
            "\<span class=mceNonEditable\>" + "<a class=\"externalWiki\" href=\"\/projects\/#{@projectIdentifier}\/wiki\/#{wikiPage}\">#{title}</a>" + "\<\/span\>"
          end
        end
        
        # Auto links urls in text
        def inline_auto_link(text)
          text.gsub!(AUTO_LINK_RE) do
          all, leading, proto, url, post = $&, $1, $2, $3, $6
          if leading =~ /<a\s/i || leading =~ /![<>=]?/
            # don't replace URL's that are already linked
            # and URL's prefixed with ! !> !< != (textile images)
            all
          else            
            %(#{leading}<a class="external" href="#{proto=="www."?"http://www.":proto}#{url}">#{proto + url}</a>#{post})
          end
        end
      end
      
      # Turns all email addresses into clickable links (code from Rails).
      def inline_auto_mailto(text)
        text.gsub!(/([\w\.!#\$%\-+.]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+)/) do
          mail = $1
          if text.match(/<a\b[^>]*>(.*)(#{Regexp.escape(mail)})(.*)<\/a>/)
            mail
          else
            content_tag('a', mail, :href => "mailto:#{mail}", :class => "email")
          end
        end
      end
      
      # Converts text like "r123" into a link for a revision number 123
      def inline_revision_link(text)
        text.gsub!(/r(\d+)/) do |m|
          revision_number = $~[1]
          "\<span class=mceNonEditable\>" + "<a class=\"revisionLink\" href=\"\/projects\/#{@projectName}\/repository\/revisions\/#{revision_number}\">r#{revision_number}</a>" + "\<\/span\>"
        end 
      end
      
      # Converts text like "#123" into a link for a issue number 123
      def inline_issue_link(text)
        text.gsub!(/\W#(\d+)\b/) do |m|
          issue_number = $~[1]
          if(!issue_number.nil?)
            "\<span class=mceNonEditable\>" + "<a class=\"issueLink\" href=\"../../../../../issues\/#{issue_number}\">\##{issue_number}</a>" + "\<\/span\>"
          end
        end 
      end
      
      # Converts documents links such as
      # document#123 (123 is id of document)
      # document:NameOfDocument
      # document:"Long document name with spaces"
      def inline_document_link(text)
        text.gsub!(/document(\#(\d+)|\:(\w+|\"(.*)\"))/) do |m|
          document_id = $~[2]
          document_short_name = $~[3]
          document_long_name = $~[4]
          if(!document_long_name.nil?)
            @documents = Document.find(:all)
            @documents.each{|document|
              if(document.title == document_long_name)
                @document_identifier = document.id
              end
            }
            "\<span class=mceNonEditable\>" + "<a class=\"documentLink\" href=\"../../../../../documents\/#{@document_identifier}}\">#{document_long_name}</a>" + "\<\/span\>"
          elsif(!document_short_name.nil?)
            @documents = Document.find(:all)
            @documents.each{|document|
              if(document.title == document_short_name)
                @document_identifier = document.id
              end
            }
            "\<span class=mceNonEditable\>" + "<a class=\"documentLink\" href=\"../../../../../documents\/#{@document_identifier}\">#{document_short_name}</a>" + "\<\/span\>"
          elsif(!document_id.nil?)
            document = Document.find(document_id)
            "\<span class=mceNonEditable\>" + "<a class=\"documentLink\" href=\"../../../../../documents\/#{document_id}\">#{document.title}</a>" + "\<\/span\>"
          end
        end
      end
      
      # Converts version links such as
      # version#id
      # version:"1.0 beta 2"
      # version:1.0.0 (link to version named "1.0.0")
      def inline_version_link(text)
        text.gsub!(/version(\#(\d+)|\:((\w|\.)+|\"(.+)\"))/) do |m|
          version_id = $~[2]
          version_short_name = $~[3]
          version_long_name = $~[5]
          if(!version_long_name.nil?)
            @versions = Version.find(:all)
            @versions.each{|version|
              if(version.name == version_long_name)
                @version_id = version.id
              end
            }
            "\<span class=mceNonEditable\>" + "<a class=\"versionLink\" href=\"\/projects\/#{@projectName}\/versions\/#{@version_id}\">#{version_long_name}</a>" + "\<\/span\>"
          elsif(!version_short_name.nil?)
            @versions = Version.find(:all)
            @versions.each{|version|
              if(version.name == version_short_name)
                @version_id = version.id
              end
            }
            "\<span class=mceNonEditable\>" + "<a class=\"versionLink\" href=\"\/projects\/#{@projectName}\/versions\/#{@version_id}\">#{version_short_name}</a>" + "\<\/span\>" 
          elsif(!version_id.nil?)
            version = Version.find(version_id)
            "\<span class=mceNonEditable\>" + "<a class=\"versionLink\" href=\"\/projects\/#{@projectName}\/versions\/#{version_id}\">#{version.name}</a>" + "\<\/span\>"
          end
        end
      end
      
      def inline_attachment_link(text)
        text.gsub!(/attachment\:(\w+\.\w+)/) do |m|
          file_name = $~[1]
          @attachments = Attachment.find(:all)
          @attachments.each{|attachment|
            if(attachment.filename = file_name)
              @attachment_id = attachment.id
            end
          }
          "\<span class=mceNonEditable\>" + "<a class=\"attachmentLink\" href=\"../../../../../attachments\/#{@attachment_id}\">#{file_name}</a>" + "\<\/span\>"
        end
      end
      
      # Patch to add code highlighting support to RedCloth
      def smooth_offtags( text )
        unless @pre_list.empty?
          ## replace <pre> content
          text.gsub!(/<redpre#(\d+)>/) do
            content = @pre_list[$1.to_i]
            if content.match(/<code\s+class="(\w+)">\s?(.+)/m)
              content = "<code class=\"#{$1} syntaxhl\">" + 
                Redmine::SyntaxHighlighting.highlight_by_language($2, $1)
            end
            content
          end
        end
      end
      
      # Patch to add 'table of content' support to RedCloth
      def textile_p_withtoc(tag, atts, cite, content)
        # removes wiki links from the item
        toc_item = content.gsub(/(\[\[([^\]\|]*)(\|([^\]]*))?\]\])/) { $4 || $2 }
        # sanitizes titles from links
        # see redcloth3.rb, same as "#{pre}#{text}#{post}"
        toc_item.gsub!(LINK_RE) { [$2, $4, $9].join }
        # sanitizes image links from titles
        toc_item.gsub!(IMAGE_RE) { [$5].join }
        # removes styles
        # eg. %{color:red}Triggers% => Triggers
        toc_item.gsub! %r[%\{[^\}]*\}([^%]+)%], '\\1'
        
        # replaces non word caracters by dashes
        anchor = toc_item.gsub(%r{[^\w\s\-]}, '').gsub(%r{\s+(\-+\s*)?}, '-')

        unless anchor.blank?
          if tag =~ /^h(\d)$/
            @toc << [$1.to_i, anchor, toc_item]
          end
          atts << " id=\"#{anchor}\""
          content = content + "<a href=\"##{anchor}\" class=\"wiki-anchor\">&para;</a>"
        end
        textile_p(tag, atts, cite, content)
      end

      alias :textile_h1 :textile_p_withtoc
      alias :textile_h2 :textile_p_withtoc
      alias :textile_h3 :textile_p_withtoc
        
      def setProjectNameAndPath(project, url)
          @projectName = project
          @serverUrl = url
      end
      
      def initialize(*args)
        super
        self.hard_breaks=true
        self.no_span_caps=true
        self.filter_styles=true
      end
      
      def to_html
        @toc = []
        super(*RULES)
      end
  
      private
  
        # Patch for RedCloth.  Fixed in RedCloth r128 but _why hasn't released it yet.
        # <a href="http://code.whytheluckystiff.net/redcloth/changeset/128">http://code.whytheluckystiff.net/redcloth/changeset/128</a>
        def hard_break( text ) 
          text.gsub!( /(.)\n(?!\n|\Z|>| *([#*=]+(\s|$)|[{|]))/, "\\1<br />" ) if hard_breaks
        end
        
        AUTO_LINK_RE = %r{
                        (                          # leading text
                          <\w+.*?>|                # leading HTML tag, or
                          [^=<>!:'"/]|             # leading punctuation, or 
                          ^                        # beginning of line
                        )
                        (
                          (?:https?://)|           # protocol spec, or
                          (?:s?ftps?://)|
                          (?:www\.)                # www.*
                        )
                        (
                          (\S+?)                   # url
                          (\/)?                    # slash
                        )
                        ([^\w\=\/;\(\)]*?)               # post
                        (?=<|\s|$)
                       }x unless const_defined?(:AUTO_LINK_RE)
  
    end

class ConvertController < ApplicationController
  unloadable
      
  def wysiwygtohtmltotextile
    @text = params[:content][:text] 
    # name="content[text]" --- wiki page
    # name="issue[description]" -- issue
    # name="notes" -- note
    # name="settings[mail_handler_body_delimiters]" - settings
    # name="project[description]"
    # name="message[content]" -- forum
    @text=Undress(@text).to_textile
    render :partial => 'convert'
  end
  
  def wysiwygtotextiletohtml
    @text=params[:content][:text]
    # get project name
    @fullPath=request.referer
    @fullPath.gsub!(/.*\/projects\/(\w+)\/.*/) do |m|
      @projectName =$~[1]
    end
    @serverFullUrl = url_for(:controller => 'projects')
    #@text=RedCloth3.new(params[:content][:text]).to_html
    #@text = @text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
    formatter = HTMLFormatter.new(@text)
    formatter.setProjectNameAndPath(@projectName, @serverFullUrl)
    @text = formatter.to_html
    #@text=HTMLFormatter.new(@projectName, @text).to_html
    render :partial => 'convert'
  end
end
