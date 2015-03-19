require_relative '../phase6/controller_base'
require_relative '../phase6/router'

module RouteHelper
  def button_to(text, url, **options)
    defaults = { method: :get, class: :button_to }
    options = defaults.merge(options)
    getting = options[:method] == :get
    method = getting ? "get" : "post"
    hiddentag = getting ? "<input name='_method' type='hidden' value'#{method}'>\n" : ""
    <<-HTML
      <form action="#{url}" class="#{defaults[:class]}" method="#{method}">
        <div>
          #{hiddentag}<input type="submit" value="#{text}">
          <input type="authenticity_token" type="hidden" value="#{form_authenticity_token}">
        </div>
      </form>
    HTML
  end
end

module Bonus
  class Flash
    def initialize(res, flashes = {})
      @flash_buffer = flashes
      @next_flash = {}
      @res = res
    end

    def [](key)
      @flash_buffer[key]
    end

    def []=(key, value)
      @next_flash.merge!({key => value})
      @res.cookies.reject! { |cookie| cookie.name == "_rails_lite_app.flash" }
      new_cookie = WEBrick::Cookie.new("_rails_lite_app.flash", JSON.generate(@next_flash))
      new_cookie.path = "/"
      @res.cookies << new_cookie
    end

    def now
      @flash_buffer
    end
  end

  class Params < Phase5::Params
  end

  class ControllerBase < Phase6::ControllerBase
    include RouteHelper

    def initialize(req, res, route_params = {})
      @req = req
      @res = res
      @params = Params.new(req, route_params)
      set_flash_from_cookie
      reset_flash
    end

    def set_flash_from_cookie
     #  debugger # if self.class == Cats2Controller
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
  end

  class Router < Phase6::Router
    def run(req, res)
      route = self.match(req)
      if route
        route.run(req, res)
      else
        res.status = 404
        render_content("you got a 404, baby", "text/text")
      end
    end

    def add_route(pattern, method, controller_class, action_name)
      @routes << Route.new(pattern, method, controller_class, action_name)
    end

    def draw(&proc)
      self.instance_eval(&proc)
      create_route_helpers
    end

    def create_route_helpers
      routes.each do |route|
        path_nouns = route.path[1..-1].split("/").reject { |noun| noun[0] == ":" }
        path_nouns = path_nouns.each_with_index.map do |path_noun, index|
          if index == path_nouns.length - 1
            [:show, :new, :edit, :delete].include?(route.action_name) ? path_noun.singularize : path_noun
          else
            path_noun.singularize
          end
        end
        if [:new, :edit].include?(route.action_name)
          path_verb = route.action_name.to_s + "_"
          path_nouns.pop
        else
          path_verb = ""
        end
        method_name = path_verb + path_nouns.join("_") + "_path"
        wildcards = route.path.split("/").select { |noun| noun[0] == ":" }
        RouteHelper.send(:define_method, method_name) do |*args|
          raise "Wrong number of arguments" if args.length != wildcards.length
          args.map! do |arg|
            arg.is_a?(Integer) ? arg : arg.id
          end
          route.path.gsub(/:([\w_-]*)\//) { |m| args.shift.to_s + "/" }
        end
      end
    end
  end

  class Route < Phase6::Route
    attr_reader :path

    def initialize(path, http_method, controller_class, action_name)
      @path = path
      @pattern = pattern_from_path(path)
      @http_method = http_method
      @controller_class = controller_class
      @action_name = action_name
    end
    # get "/cats/:cat_id/statuses"
    # get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$")
    def pattern_from_path(path)
      Regexp.new("^" + path.gsub(/:([\w_-]*)\//, '(?<\1>\d+)/') + "$")
    end

    def run(req, res)
      matches = pattern.match(req.path)
      route_params = Hash[matches.names.zip(matches.captures)]
      new_controller = controller_class.new(req, res, route_params)
      new_controller.invoke_action(action_name)
    end
  end

  class Session < Phase4::Session
    def store_session(res)
      cookie = WEBrick::Cookie.new("_rails_lite_app", JSON.generate(@session))
      cookie.path = "/"
      res.cookies << cookie
    end
  end
end
