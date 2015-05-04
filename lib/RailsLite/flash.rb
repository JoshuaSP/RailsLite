module RailsLite
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
end
