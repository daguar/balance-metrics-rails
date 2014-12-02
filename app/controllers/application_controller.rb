class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  force_ssl if Rails.env == 'production'

  def index
    @successful_message_strings = [
    'Hi! Your food stamp balance is%',
    '%El saldo de su cuenta%',
    'Hi! Your food and nutrition benefits balance is%']

    @error_message_strings = ["I'm really sorry! We're having trouble contacting the EBT system right now.%"]

    # Includes orry_try_again and card_number_not_found_message messages
    @failure_message_strings = [
    "Sorry! That number doesn't look right.%",
    'Perdon, ese número de EBT no esta trabajando%',
    "I'm sorry, that card number was not found.%",
    'Lo siento, no se encontró el número de tarjeta%']

    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    @phone_number_hash = Hash.new
    client.account.incoming_phone_numbers.list.each do |number|
      funnel_name = number.friendly_name
      @phone_number_hash[number.phone_number] = funnel_name
    end

    # Successes
    messages = Message.arel_table
    @all_successful_messages = Message.where(messages[:body].matches_any(@successful_message_strings))
    @count_of_successful_messages = @all_successful_messages.count
    @successful_messages_by_week = @all_successful_messages.group_by_week(:date_sent).count
    @successful_messages_by_source = @all_successful_messages.group(:from_number).count
    @successful_messages_by_source = @successful_messages_by_source.map { |k,v| [@phone_number_hash[k],v] }.sort { |a,b| b[1] <=> a[1] }

    # Failures
    @all_failure_messages = Message.where(messages[:body].matches_any(@failure_message_strings))
    @count_of_failure_messages = @all_failure_messages.count
    @failure_messages_by_week = @all_failure_messages.group_by_week(:date_sent).count
    @failure_messages_by_day = @all_failure_messages.group_by_day(:date_sent).count
    @average_count_of_weekly_failures = @failure_messages_by_week.values.inject { |sum, e| sum + e } / @failure_messages_by_week.size

    @count_of_failures_last_7_days = 0
    @failure_messages_by_day.keys[-7..-1].each do | day |
      @count_of_failures_last_7_days += @failure_messages_by_day[day]
    end
    @failure_messages_by_source = @all_failure_messages.group(:from_number).count
    @failure_messages_by_source = @failure_messages_by_source.map { |k,v| [@phone_number_hash[k],v] }.sort { |a,b| b[1] <=> a[1] }

    # Errors
    @count_of_error_messages = Message.where(messages[:body].matches_any(@error_message_strings)).count
    @error_messages_by_week = Message.where(messages[:body].matches_any(@error_message_strings)).group_by_week(:date_sent).count

    # Uniques
    @number_of_unique_phone_numbers_with_one_successful_balance_check = @all_successful_messages.select(:to_number).uniq.count

    # Engagement
    users_checks = @all_successful_messages.group(:to_number).count
    users_with_two_or_more_checks = users_checks.count { |k, v| v > 1 }
    @total_engagement_rate = users_with_two_or_more_checks.to_f / users_checks.keys.count

  
    # By source
    # @engagement_rate_by_source['total'] = users_with_two_or_more_checks.to_f / users_checks.keys.count
    @metrics_by_source = Hash.new

    @phone_number_hash.keys.each do |s|
      source_name = @phone_number_hash[s]

      # checks
      checks = @all_successful_messages.select(:to_number).where(from_number: s).count
      if checks == 0
        next
      end
      @metrics_by_source[source_name] = Hash.new
      @metrics_by_source[source_name]['checks'] = checks
      

      # Uniques
      uniques = @all_successful_messages.select(:to_number).where(from_number: s).uniq.count
      @metrics_by_source[source_name]['uniques'] = uniques

      # Engagement
      users_checks = @all_successful_messages.where(from_number: s).group(:to_number).count
      users_with_two_or_more_checks = users_checks.count { |k, v| v > 1 }
      engagement_rate = users_with_two_or_more_checks.to_f / users_checks.keys.count
      @metrics_by_source[source_name]['engagement'] = engagement_rate if !engagement_rate.nan?
    end

    
    # Checks
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
          "title"=> "Balance Metrics - Checks",
          "yaxis" => {"title" => "# of successful checks"}
        },
        "world_readable"=> true
      }

    @successful_messages_plot_url = view_context.create_plot("plot", args, kwargs)

    # Uniques
    all_days_with_successful_message = @all_successful_messages.select(:date_sent).map { |m| m.date_sent.to_date}.uniq.sort
    x = all_days_with_successful_message
    y = []
    all_days_with_successful_message.each do |day|
      y << @all_successful_messages.select(:to_number).where(messages[:date_sent].lt(day+1)).uniq.count
    end

    args = [x, y]
    kwargs={
      "filename"=> "Balance Metrics - Uniques",
      "fileopt"=> "overwrite",
      "style"=> {
        "type"=> "scatter"
        },
        "layout"=> {
          "title"=> "Balance Metrics - Uniques",
          "showlegend" => false,
          "yaxis" => {"title" => "# of unique phone numbers with 1+ successful check"}
        },
        "world_readable"=> true
      }

    @uniques_plot_url = view_context.create_plot("plot", args, kwargs)

  end
end
