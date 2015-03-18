require_relative '../phase2/controller_base'
require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'byebug'

module Phase3
  class ControllerBase < Phase2::ControllerBase
    # use ERB and binding to evaluate templates
    # pass the rendered html to render_content
    def render(template_name)
      controller_name = self.class.name.underscore
      erb = File.read("views/#{controller_name}/#{template_name}.html.erb")
      render_content(ERB.new(erb).result(binding), "text/html")
    end
  end
end
