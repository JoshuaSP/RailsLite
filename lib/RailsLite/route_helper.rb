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
