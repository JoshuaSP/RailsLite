module Phase2
  class ControllerBase
    attr_reader :req, :res

    # Setup the controller
    def initialize(req, res)
      @req = req
      @res = res
      @already_built_response = false
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
    end

    def redirect_to(url)
      if @already_built_response
        raise
      else
        @already_built_response = true
        @res.header["location"] = url
        @res.status = 302
      end
    end
  end
end
