require 'uri'

module RailsLite
  class Params
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

    def parse_key(key)
      key.split(/\]\[|\[|\]/)
    end
  end
end
