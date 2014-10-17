module ApplicationHelper
  def create_daily_timeseries_from_messages(messages)
    messages_by_day = messages.group_by_day(:date_sent).count
    days = messages_by_day.keys.map { |x| x.to_date}
    daily_count = messages_by_day.values
    sum = 0
    cumulative_count = daily_count.map { |x| sum += x}
    puts "#{[days, cumulative_count]}"
    return [days, cumulative_count]
  end

  def create_plot(origin, args, kwargs)
    # See REST API docs: https://plot.ly/rest/
    uri = URI.parse("https://plot.ly/clientresp")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({"un" => ENV['PLOTLY_USERNAME'],
                          "key" => ENV['PLOTLY_KEY'],
                          "origin" => origin,
                          "platform" => "ruby",
                          "args" => args.to_json,
                          "kwargs" => kwargs.to_json})
    response = http.request(request)
    response_json = JSON.parse(response.body)
    response_json['url']
  end
end