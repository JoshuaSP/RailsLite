require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'byebug'
require_relative 'flash'
require_relative 'params'
require_relative 'route_helper'
require_relative 'router'
require_relative 'session'

module RailsLite
  class ControllerBase
    include RouteHelper
    attr_reader :req, :res, :params

    def initialize(req, res, route_params = {})
      @req = req
      @res = res
      @params = Params.new(req, route_params)
      set_flash_from_cookie
      reset_flash
    end

    def render(template_name)
      controller_name = self.class.name.underscore
      erb = File.read("views/#{controller_name}/#{template_name}.html.erb")
      render_content(ERB.new(erb).result(binding), "text/html")
    end

    def set_flash_from_cookie
      req.cookies.each do |cookie|
        if cookie.name == "_rails_lite_app.flash" && cookie.value != ""
          @flash = Flash.new(@res, JSON.parse(cookie.value))
        end
      end
    end

    def reset_flash
      @res.cookies << WEBrick::Cookie.new("_rails_lite_app.flash", "")
    end

    def flash
      @flash ||= Flash.new(@res)
    end

    def set_authenticity_token
      session["authenticity_token"] = form_authenticity_token
    end


    def form_authenticity_token
      @form_authenticity_token ||= SecureRandom::urlsafe_base64(19)
    end

    def session
      @session ||= Session.new(req)
    end

    def invoke_action(name)
      if [:post, :put, :patch, :delete].include?(@req.request_method.downcase.to_sym)
        raise "Bad Authenticity Token" unless params["authenticity_token"] == session["authenticity_token"]
      end
      set_authenticity_token
      self.send(name)
      render(name) unless already_built_response?
    end

    def already_built_response?
      @already_built_response
    end

    def render_content(content, content_type)
      if @already_built_response
        raise
      else
        @already_built_response = true
        @res.body = content
        @res.content_type = content_type
      end
      session.store_session(res)
    end

    def invoke_action(name)
      self.send(name)
      render(name) unless already_built_response?
    end

    def redirect_to(url)
      if @already_built_response
        raise
      else
        @already_built_response = true
        @res.header["location"] = url
        @res.status = 302
      end
      session.store_session(res)
    end

    def session
      @session ||= Session.new(req)
    end
  end
end
