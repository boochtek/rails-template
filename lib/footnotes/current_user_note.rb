if defined?(Footnotes)
  module Footnotes
    module Notes
      class CurrentUserNote < AbstractNote
        # This method always receives a controller
        def initialize(controller)
          @current_user = controller.instance_variable_get('@current_user')
        end

        # The name that will appear as legend in fieldsets.
        def legend
          "Current user: #{@current_user.name}"
        end

        # This note is only valid if we actually found a user; if it's not valid, it won't be displayed.
        def valid?
          @current_user
        end

        # The fieldset content
        def content
          escape(@current_user.inspect)
        end
      end
    end
  end
end
