require 'webrick'
require_relative '../lib/RailsLite/controller_base'


# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPRequest.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/HTTPResponse.html
# http://www.ruby-doc.org/stdlib-2.0/libdoc/webrick/rdoc/WEBrick/Cookie.html

$cats = [
  { id: 1, name: "Curie" },
  { id: 2, name: "Markov" }
]

$statuses = [
  { id: 1, cat_id: 1, text: "Curie loves string!" },
  { id: 2, cat_id: 2, text: "Markov is mighty!" },
  { id: 3, cat_id: 1, text: "Curie is cool!" }
]

class StatusesController < RailsLite::ControllerBase
  def index
    statuses = $statuses.select do |s|
      s[:cat_id] == Integer(params[:cat_id])
    end
    require 'byebug'

    flash.now["coolness"] = "ahha!"
    flash["coolness"] = "later"
    render_content(statuses.to_s + "\n" + @flash["coolness"] + "\n" + new_cat_path, "text/text")
  end

  def new
  end
end

class Cats2Controller < RailsLite::ControllerBase
  # def index
  #   render_content($cats.to_s, "text/text")
  # end
  def index
  end

  def new
  end

  def create
    render_content(@req.body, "text/text")
  end
end

router = RailsLite::Router.new
router.draw do
  # get Regexp.new("^/cats$"), Cats2Controller, :index
  # get Regexp.new("^/cats/(?<cat_id>\\d+)/statuses$"), StatusesController, :index
  get "/cats", Cats2Controller, :index
  get "/cats/:cat_id/statuses", StatusesController, :index
  get "/cats/new", Cats2Controller, :new
  post "/cats", Cats2Controller, :create
  delete "/cats/:id", Cats2Controller, :destroy
end

def rack_lite(req)
  method_reg = /method=(patch|put|delete)/
  if method_reg.match(req.body)
    req.request_method = method_reg[1].upcase
  end
end

server = WEBrick::HTTPServer.new(Port: 3000)
server.mount_proc('/') do |req, res|
  rack_lite(req)
  route = router.run(req, res)
end

trap('INT') { server.shutdown }
server.start
