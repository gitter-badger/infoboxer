# encoding: utf-8
module Infoboxer
  class Parser
    module Inline
      include Tree
      
      def inline(until_pattern = nil)
        start = @context.lineno
        nodes = Nodes[]
        guarded_loop do
          chunk = @context.scan_until(re.inline_until_cache[until_pattern])
          nodes << chunk

          break if @context.matched_inline?(until_pattern)

          nodes << inline_formatting(@context.matched) unless @context.matched.empty?

          if @context.eof?
            break unless until_pattern
            @context.fail!("#{until_pattern} not found, starting from #{start}")
          end
          
          if @context.eol?
            nodes << "\n"
            @context.next!
          end
        end
        
        nodes
      end

      def short_inline(until_pattern = nil)
        nodes = Nodes[]
        guarded_loop do
          # FIXME: quick and UGLY IS HELL JUST TRYING TO MAKE THE SHIT WORK
          if @context.inline_eol_sign
            chunk = @context.scan_until(re.short_inline_until_cache_brackets[until_pattern])
          else
            chunk = @context.scan_until(re.short_inline_until_cache[until_pattern])
          end
          nodes << chunk

          break if @context.matched_inline?(until_pattern)

          nodes << inline_formatting(@context.matched)

          break if @context.inline_eol?(until_pattern)
        end
        
        nodes
      end

      def long_inline(until_pattern = nil)
        nodes = Nodes[]
        guarded_loop do
          chunk = @context.scan_until(re.inline_until_cache[until_pattern])
          nodes << chunk

          break if @context.matched?(until_pattern)

          nodes << inline_formatting(@context.matched) unless @context.matched.empty?

          if @context.eof?
            break unless until_pattern
            @context.fail!("#{until_pattern} not found")
          end
          
          if @context.eol?
            @context.next!
            paragraphs(until_pattern).each do |p|
              nodes << p
            end
            break
          end
        end
        
        nodes
      end

      private
        def inline_formatting(match)
          case match
          when "'''''"
            BoldItalic.new(short_inline(/'''''/))
          when "'''"
            Bold.new(short_inline(/'''/))
          when "''"
            Italic.new(short_inline(/''/))
          when '[['
            if @context.check(re.file_namespace)
              image
            else
              wikilink
            end
          when /\[(.+)/
            external_link($1)
          when '{{'
            template
          when /<nowiki([^>]*)>/
            nowiki
          when /<ref([^>]*)\/>/
            reference($1, true)
          when /<ref([^>]*)>/
            reference($1)
          when '<'
            html || Text.new(match) # it was not HTML, just accidental <
          else
            match # FIXME: TEMP
          end
        end

        # http://en.wikipedia.org/wiki/Help:Link#Wikilinks
        # [[abc]]
        # [[a|b]]
        def wikilink
          link = @context.scan_continued_until(/\||\]\]/)
          caption = inline(/\]\]/) if @context.matched == '|'
          Wikilink.new(link, caption)
        end

        # http://en.wikipedia.org/wiki/Help:Link#External_links
        # [http://www.example.org]
        # [http://www.example.org link name]
        def external_link(protocol)
          link = @context.scan_continued_until(/\s+|\]/)
          if @context.matched =~ /\s+/
            @context.push_eol_sign(/^\]/)
            caption = short_inline(/\]/) 
            @context.pop_eol_sign
          end
          ExternalLink.new(protocol + link, caption)
        end

        def reference(param_str, closed = false)
          children = closed ? Nodes[] : long_inline(/<\/ref>/)
          Ref.new(children, parse_params(param_str))
        end

        def nowiki
          Text.new(@context.scan_continued_until(/<\/nowiki>/))
        end
      end

      require_relative 'image'
      require_relative 'html'
      require_relative 'template'
      include Infoboxer::Parser::Image
      include Infoboxer::Parser::HTML
      include Infoboxer::Parser::Template
  end
end
