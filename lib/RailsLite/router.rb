module RailsLite
  class Route
    attr_reader :pattern, :http_method, :controller_class, :action_name, :path

    def initialize(path, http_method, controller_class, action_name)
      @path = path
      @pattern = pattern_from_path(path)
      @http_method = http_method
      @controller_class = controller_class
      @action_name = action_name
    end

    # checks if pattern matches path and method matches request method
    def matches?(req)
      req.request_method.downcase.to_sym == http_method && !!pattern.match(req.path)
    end

    def pattern_from_path(path)
      Regexp.new("^" + path.gsub(/:([\w_-]*)\//, '(?<\1>\d+)/') + "$")
    end

    # use pattern to pull out route params
    # instantiate controller and call controller action
    def run(req, res)
      matches = pattern.match(req.path)
      route_params = Hash[matches.names.zip(matches.captures)]
      new_controller = controller_class.new(req, res, route_params)
      new_controller.invoke_action(action_name)
    end
  end

  class Router
    attr_reader :routes

    def initialize
      @routes = []
    end

    def route_paths
      routes.map { |route| route.path }
    end

    # simply adds a new route to the list of routes
    def add_route(pattern, method, controller_class, action_name)
      @routes << Route.new(pattern, method, controller_class, action_name)
    end

    # evaluate the proc in the context of the instance
    def draw(&proc)
      self.instance_eval(&proc)
      create_route_helpers
    end

    # make each of these methods that
    # when called add route
    [:get, :post, :put, :delete].each do |http_method|
      define_method(http_method) do |pattern, controller_class, action_name|
        add_route(pattern, http_method, controller_class, action_name)
      end
    end

    def match(req)
      @routes.find { |route| route.matches?(req) }
    end

    def run(req, res)
      route = self.match(req)
      if route
        route.run(req, res)
      else
        res.status = 404
        render_content("you got a 404, baby", "text/text")
      end
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
end
