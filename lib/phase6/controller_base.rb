require_relative '../phase5/controller_base'
require 'byebug'

module Phase6
  class ControllerBase < Phase5::ControllerBase
    # use this with the router to call action_name (:index, :show, :create...)
    def invoke_action(name)
      self.send(name)
      render(name) unless already_built_response?
    end
  end
end
