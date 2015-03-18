require_relative '../phase6/controller_base'

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

  class ControllerBase < Phase6::ControllerBase

    def initialize(req, res, route_params = {})
      super
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
      # @res.cookies << WEBrick::Cookie.new("_rails_lite_app.flash", "")
    end

    def flash
      @flash ||= Flash.new(@res)
    end
  end
end
