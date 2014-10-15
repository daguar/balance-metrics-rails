class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    @phone_number_hash = Hash.new
    client.account.incoming_phone_numbers.list.each do |number|
      funnel_name = number.friendly_name
      @phone_number_hash[number.phone_number] = funnel_name
    end

    messages = Message.arel_table
    @all_successful_messages = Message.where(messages[:body].matches("Hi! Your food stamp balance is%").or(messages[:body].matches("%El saldo de su cuenta%")))
    @count_of_successful_messages = @all_successful_messages.count
    @successful_messages_by_week = Message.where(messages[:body].matches("Hi! Your food stamp balance is%").or(messages[:body].matches("%El saldo de su cuenta%"))).group_by_week(:date_sent).count
    @count_of_error_messages = Message.where(messages[:body].matches("I'm really sorry! We're having trouble contacting the EBT system right now.%")).count
    @error_messages_by_week = Message.where(messages[:body].matches("I'm really sorry! We're having trouble contacting the EBT system right now.%")).group_by_week(:date_sent).count
    @successful_messages_by_source = Message.where(messages[:body].matches("Hi! Your food stamp balance is %").or(messages[:body].matches("%El saldo de su cuenta%"))).group(:from_number).count
    @successful_messages_by_source = @successful_messages_by_source.map { |k,v| [@phone_number_hash[k],v] }.sort { |a,b| b[1] <=> a[1] }

    # Charts
    # all_successful_messages_data = view_context.create_daily_timeseries_from_messages(@all_successful_messages)
    # data_total = {'name' => 'total',
    #         'x' => all_successful_messages_data[0],
    #         'y' => all_successful_messages_data[1]}
    args = []
    @phone_number_hash.keys.each do |source_number|
      successful_messages_for_source = @all_successful_messages.where(messages[:from_number].eq(source_number))
      if successful_messages_for_source.any?
        data = view_context.create_daily_timeseries_from_messages(successful_messages_for_source)
        data_hash = {'name' => @phone_number_hash[source_number],
            'x' => data[0],
            'y' => data[1]}
        args << data_hash
      end
    end

    kwargs={
      "filename"=> "Balance Metrics",
      "fileopt"=> "overwrite",
      "style"=> {
        "type"=> "scatter"
        },
        "layout"=> {
          "title"=> "Balance Metrics",
          "xaxis" => {"type" => "date"},
          "xaxis" => {"name" => "# of successful balance checks"}
        },
        "world_readable"=> true
      }

    @plot_url = view_context.create_plot("plot", args, kwargs)
  end
end
