require 'json'
require 'webrick'

module RailsLite
  class Session
    # find the cookie for this app
    # deserialize the cookie into a hash
    def initialize(req)
      @session = {}
      req.cookies.each do |cookie|
        if cookie.name == "_rails_lite_app"
          @session = JSON.parse(cookie.value)
        end
      end
    end

    def [](key)
      @session[key]
    end

    def []=(key, val)
      @session[key] = val
    end

    # serialize the hash into json and save in a cookie
    # add to the response's cookies
    def store_session(res)
      cookie = WEBrick::Cookie.new("_rails_lite_app", JSON.generate(@session))
      cookie.path = "/"
      res.cookies << cookie
    end
  end
end
