module Footnotes
  module Notes
    class CurrentUserNote < AbstractNote
      # This method always receives a controller
      def initialize(controller)
        @current_user = controller.instance_variable_get('@current_user')
      end
      # The name that will appear as legend in fieldsets
      def legend
        "Current user: #{@current_user.name}"
      end
      # This Note is only valid if we actually found an user; if itÕs not valid, it wonÕt be displayed.
      def valid?
        @current_user
      end
      # The fieldset content
      def content
        escape(@current_user.inspect)
      end
    end
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
        '<pre>' + escape(Object.constants.select{|c| ![Class, Module].include?(c.constantize.class)}.sort.map{|c| {c => "#{c.constantize}"}}.to_yaml) + '</pre>'
      end
    end
  end
end
Footnotes::Filter.notes += [:current_user, :global_constants]
