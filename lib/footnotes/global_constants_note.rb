if defined?(Footnotes)
  module Footnotes
    module Notes
      class GlobalConstantsNote < AbstractNote
        # Returns the title that represents this note.
        def title
          'Global Constants'
        end

        # The name that will appear as legend in fieldsets
        def legend
          'Global Constants'
        end

        # The fieldset content
        def content
          '<pre>' + escape(Object.constants.select{|c| ![Class, Module].include?(c.to_s.constantize.class)}.sort.map{|c| "#{c} = #{c.to_s.constantize.inspect}"}.join("\n")) + '</pre>'
        end
      end
    end
  end
end
