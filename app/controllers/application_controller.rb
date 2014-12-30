class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :set_global_variables
  around_filter :profile if Rails.env == 'development'
  force_ssl if Rails.env == 'production'

  def set_global_variables
    @successful_message_strings = [
      'Hi! Your food stamp balance is%',
      '%El saldo de su cuenta%',
      'Hi! Your food and nutrition benefits balance is%']

    # Includes orry_try_again and card_number_not_found_message messages
    @failure_message_strings = [
      "Sorry! That number doesn't look right.%",
      'Perdon, ese número de EBT no esta trabajando%',
      "I'm sorry, that card number was not found.%",
      'Lo siento, no se encontró el número de tarjeta%']

    @error_message_strings = ["I'm really sorry! We're having trouble contacting the EBT system right now.%"]

    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    @phone_number_hash = Hash.new
    client.account.incoming_phone_numbers.list.each do |number|
      funnel_name = number.friendly_name
      @phone_number_hash[number.phone_number] = funnel_name
    end

    @messages = Message.arel_table
    @all_successful_messages = Message.where(@messages[:body].matches_any(@successful_message_strings))
  end

  def profile
    if params[:profile] && result = RubyProf.profile { yield }

      out = StringIO.new
      RubyProf::GraphHtmlPrinter.new(result).print out, :min_percent => 0
      self.response_body = out.string
      printer = RubyProf::MultiPrinter.new(result)
      # render :text => out.string
      # render :json => {'value' => monthly_active_users}

    else
      yield
    end
  end

  def index
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
    sql = "WITH rankings AS (
            SELECT m.date_sent::date,
                  ROW_NUMBER() OVER(PARTITION BY m.to_number 
                                         ORDER BY m.date_sent ASC) AS rk
              FROM MESSAGES m
              WHERE m.body SIMILAR TO '(Hi! Your food stamp balance is%|%El saldo de su cuenta%|Hi! Your food and nutrition benefits balance is%)'),
          
          new_users AS (
            SELECT r.*
              FROM rankings r
              WHERE r.rk = 1)

          SELECT n.date_sent, SUM(n.rk)
            FROM new_users n
            GROUP BY n.date_sent
            ORDER BY n.date_sent ASC;"

    new_user_counts_by_day = ActiveRecord::Base.connection.execute(sql)
    days = new_user_counts_by_day.values.map { |v| v[0]}
    sum = 0
    cumulative_users_daily = new_user_counts_by_day.values.map { |v| sum += v[1].to_i}

    args = [days, cumulative_users_daily]
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

  # Ducksboard routes
  def mau
    monthly_successful_checks = @all_successful_messages.where("date_sent >= ?", Time.now - 30.days)
    monthly_active_users = monthly_successful_checks.select(:to_number).uniq.count
    render :json => {'value' => monthly_active_users}
  end

  def monthly_checks
    monthly_successful_checks = @all_successful_messages.where("date_sent >= ?", Time.now - 30.days)
    render :json => {'value' => monthly_successful_checks.count}
  end

  def leaderboard
    # Docs https://dev.ducksboard.com/apidoc/slot-kinds/#leaderboards
    # {"name": "sf_food_bank", "values": [checks, users, engagement]},
    @metrics_by_source = Hash.new
    @phone_number_hash.keys.each do |s|
      source_name = @phone_number_hash[s]

      # Checks
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
    
    @board = []
    sorted_metrics_by_source = @metrics_by_source.sort_by { |name, metrics| -metrics['checks']}
    sorted_metrics_by_source.each do |name, metrics|
      @board << {
        "name" => name,
        "values" => [metrics['checks'], metrics['uniques'], metrics['engagement']]
      }
    end
    render :json => {'value' => {"board" => @board}}
  end
end
