#
# Based on undress gem source . Corrections by Alexey Kalmykov (alexey.kalmykov@lanit-tercom.com), Lanit-Tercom, Inc
#
require File.expand_path(File.dirname(__FILE__) + "/../undress")

module Undress
  class Textile < Grammar
    whitelist_attributes :class, :id, :lang, :style, :colspan, :rowspan

    # entities
    post_processing(/&nbsp;/, " ")

    # whitespace handling
    post_processing(/\n\n+/, "\n\n")
    post_processing(/\A\s+/, "")
    post_processing(/\s+\z/, "\n")

    # special characters introduced by textile
    post_processing(/&#8230;/, "...")
    post_processing(/&#8217;/, "'")
    post_processing(/&#822[01];/, '"')
    post_processing(/&#8212;/, "--")
    post_processing(/&#8211;/, "-")
    post_processing(/(\d+\s*)&#215;(\s*\d+)/, '\1x\2')
    post_processing(/&#174;/, "(r)")
    post_processing(/&#169;/, "(c)")
    post_processing(/&#8482;/, "(tm)")

    # inline elements
    rule_for(:a) {|e|
      if(e.has_attribute?("class"))
        # LocalWiki class means that link is local wiki page(belongs to current project)
        if(e["class"] == "localWiki")
          link = e["href"]
          # Parses link like "wiki/Long_name_of_Wiki_page#+anchor+for+this+page"
          link.gsub!(/.*\/(\w+)((#)((\w|\+)+))?/) do |m|
            wikiPage = $~[1]
            delimeter = $~[3]
            anchor = $~[4]
            # Replace '+' from anchor and convert them to spaces
            if(delimeter == "#")
            anchor.gsub!(/\+/, ' ')
            end
            # Replace '_' from wiki page name and conver them to spaces
            wikiPage.gsub!(/_/, ' ')
            # Check for anchor "#"
            if(delimeter.nil?)
              if(wikiPage == content_of(e))
                "[[#{wikiPage}]]"
              else
                "\[\[#{wikiPage}|#{content_of(e)}\]\]"
              end
            else
              if(!anchor.nil?)
                "\[\[#{wikiPage}##{anchor}\]\]"
              end
            end
          end
        # ExternalWiki class means that link is wiki page from other project
        elsif(e["class"] == "externalWiki")
          link = e["href"]
          # parses link like "../../../projectidentifier/wiki/wiki_page_name"
          link.gsub!(/(\.\.\/)+(\w+)\/wiki\/(\w+)/) do |m|
            projectName = $~[2]
            wikiPage = $~[3]
            "\[\[#{projectName}\:#{wikiPage}\]\]"
          end
        # Parse revision links  
        elsif(e["class"] == "revisionLink")
          link = e["href"]
          link.gsub!(/(\.\.\/)+repository\/revisions\/(\d+)/) do |m|
            revision_number = $~[2]
            "r#{revision_number}"
          end
        # Parse issues links
        elsif(e["class"] == "issueLink")
          link = e["href"]
          link.gsub!(/(\.\.\/)+issues\/(\d+)/) do |m|
            issue_number = $~[2]
            "\##{issue_number}"
          end
        # Parse document links 
        elsif(e["class"] == "documentLink")
          link = e["href"]
          link.gsub!(/(\.\.\/)+documents\/(\d+)/) do |m|
            document_id = $~[2]
            "document##{document_id}"
          end
        # Parse version links  
        elsif(e["class"] == "versionLink")
          link = e["href"]
          link.gsub!(/(\.\.\/)+versions\/(\d+)/) do |m|
            version_id = $~[2]
            "version##{version_id}"
          end
        # Parse attachments links  
        elsif(e["class"] == "attachmentLink")
          link = e["href"]
          link.gsub!(/(\.\.\/)+attachments\/(\d+)/) do |m|
            attachment_id = $~[2]
            "attachment:#{content_of(e)}"
          end
        elsif(e["class"] == "email")
          content_of(e)
        # External class means that link is global and links to other resource 
        elsif(e["class"] == "external")
          title = e.has_attribute?("title") ? " (#{e["title"]})" : ""
          "\"#{content_of(e)}#{title}\":#{e["href"]}"
        end
      end
    }
    rule_for(:img) {|e|
      alt = e.has_attribute?("alt") ? "(#{e["alt"]})" : ""
      "!#{e["src"]}#{alt}!"
    }
    rule_for(:strong)  {|e| complete_word?(e) ? "*#{attributes(e)}#{content_of(e)}*" : "[*#{attributes(e)}#{content_of(e)}*]"}
    rule_for(:em)      {|e| complete_word?(e) ? "_#{attributes(e)}#{content_of(e)}_" : "[_#{attributes(e)}#{content_of(e)}_]"}
    rule_for(:code)    {|e| "\<code\>\n#{content_of(e)}\n\<\/code\>"}
    rule_for(:cite)    {|e| "??#{attributes(e)}#{content_of(e)}??" }
    rule_for(:sup)     {|e| surrounded_by_whitespace?(e) ? "^#{attributes(e)}#{content_of(e)}^" : "[^#{attributes(e)}#{content_of(e)}^]" }
    rule_for(:sub)     {|e| surrounded_by_whitespace?(e) ? "~#{attributes(e)}#{content_of(e)}~" : "[~#{attributes(e)}#{content_of(e)}~]" }
    rule_for(:ins)     {|e| complete_word?(e) ? "+#{attributes(e)}#{content_of(e)}+" : "[+#{attributes(e)}#{content_of(e)}+]"}
    rule_for(:del)     {|e| complete_word?(e) ? "-#{attributes(e)}#{content_of(e)}-" : "[-#{attributes(e)}#{content_of(e)}-]"}
    rule_for(:acronym) {|e| e.has_attribute?("title") ? "#{content_of(e)}(#{e["title"]})" : content_of(e) }
    rule_for(:span)    {|e|
      # means number of line from CodeRay conversion, should be deleted and replaced with new line
      if(e["class"] == "no")
        "\n"
      else
        content_of(e)
      end
    }
    

    # text formatting and layout
    rule_for(:p) do |e| 
      at = attributes(e) != "" ? "p#{at}#{attributes(e)}. " : ""
      e.parent && e.parent.name == "blockquote" ? "#{at}#{content_of(e)}\n\n" : "\n\n#{at}#{content_of(e)}\n\n"
    end
    rule_for(:br)         {|e| "\n" }
    rule_for(:blockquote) {|e| "\n\nbq#{attributes(e)}. #{content_of(e)}\n\n" }
    rule_for(:pre)        {|e|
      if e.children && e.children.all? {|n| n.text? && n.content =~ /^\s+$/ || n.elem? && n.name == "code" }
        "\n\n<pre>#{attributes(e)}#{content_of(e)}</pre>\n\n"
      else
        "<pre>#{content_of(e)}</pre>"
      end
    }

    # headings
    rule_for(:h1) {|e| "\n\nh1#{attributes(e)}. #{content_of(e)}\n\n" }
    rule_for(:h2) {|e| "\n\nh2#{attributes(e)}. #{content_of(e)}\n\n" }
    rule_for(:h3) {|e| "\n\nh3#{attributes(e)}. #{content_of(e)}\n\n" }
    rule_for(:h4) {|e| "\n\nh4#{attributes(e)}. #{content_of(e)}\n\n" }
    rule_for(:h5) {|e| "\n\nh5#{attributes(e)}. #{content_of(e)}\n\n" }
    rule_for(:h6) {|e| "\n\nh6#{attributes(e)}. #{content_of(e)}\n\n" }

    # lists
    rule_for(:li) {|e|
      token = e.parent.name == "ul" ? "*" : "#"
      nesting = e.ancestors.inject(1) {|total,node| total + (%(ul ol).include?(node.name) ? 0 : 1) }
      "\n#{token * nesting} #{content_of(e)}"
    }
    rule_for(:ul, :ol) {|e|
      if e.ancestors.detect {|node| %(ul ol).include?(node.name) }
        content_of(e)
      else
        "\n#{content_of(e)}\n\n"
      end
    }

    # definition lists
    rule_for(:dl) {|e| "\n\n#{content_of(e)}\n" }
    rule_for(:dt) {|e| "- #{content_of(e)} " }
    rule_for(:dd) {|e| ":= #{content_of(e)} =:\n" }

    # tables
    rule_for(:table)   {|e| "\n\n#{content_of(e)}\n" }
    rule_for(:tr)      {|e| "#{content_of(e)}|\n" }
    rule_for(:td, :th) {|e| "|#{e.name == "th" ? "_. " : attributes(e)}#{content_of(e)}" }

    def attributes(node) #:nodoc:
      filtered = super(node)
      
      if filtered
        
        if filtered.has_key?(:colspan)
          return "\\#{filtered[:colspan]}. "
        end

        if filtered.has_key?(:rowspan)
          return "/#{filtered[:rowspan]}. "
        end

        if filtered.has_key?(:lang)
          return "[#{filtered[:lang]}]"
        end

        if filtered.has_key?(:class) || filtered.has_key?(:id)
          klass = filtered.fetch(:class, "")
          id = filtered.fetch(:id, false) ? "#" + filtered[:id] : ""
          return "(#{klass}#{id})"
        end

        if filtered.has_key?(:style)
          return "{#{filtered[:style]}}"
        end
      end  
      ""
    end
  end

  add_markup :textile, Textile
end
