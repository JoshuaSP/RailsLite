require 'uri'

module Phase5
  class Params
    # use your initialize to merge params from
    # 1. query string
    # 2. post body
    # 3. route params
    #
    # You haven't done routing yet; but assume route params will be
    # passed in as a hash to `Params.new` as below:
    def initialize(req, route_params = {})
      @params = route_params
      @params.deep_merge!(parse_www_encoded_form(req.query_string)) if req.query_string
      @params.deep_merge!(parse_www_encoded_form(req.body)) if req.body
    end

    def [](key)
      @params[key.to_s]
    end

    def to_s
      @params.to_json.to_s
    end

    class AttributeNotFoundError < ArgumentError; end;

    private
    # this should return deeply nested hash
    # argument format
    # user[address][street]=main&user[address][zip]=89436
    # should return
    # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
    def parse_www_encoded_form(www_encoded_form)
      result = {}
      www_encoded_form.split('&').each do |piece|
        keys = parse_key(/(.*)\=/.match(piece)[1])
        value = /\=(.*)/.match(piece)[1]
        intermediate = result
        keys[0..-2].each do |key|
          if intermediate[key]
            intermediate = intermediate[key]
          else
            intermediate = intermediate[key] = {}
          end
        end
        intermediate[keys[-1]] = value
      end
      result
    end

    # this should return an array
    # user[address][street] should return ['user', 'address', 'street']
    def parse_key(key)
      key.split(/\]\[|\[|\]/)
    end
  end
end
