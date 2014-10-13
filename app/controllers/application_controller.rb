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
    @count_of_successful_messages = Message.where(messages[:body].matches("Hi! Your food stamp balance is%").or(messages[:body].matches("%El saldo de su cuenta%"))).count
    @successful_messages_by_week = Message.where(messages[:body].matches("Hi! Your food stamp balance is%").or(messages[:body].matches("%El saldo de su cuenta%"))).group_by_week(:date_sent).count
    @count_of_error_messages = Message.where(messages[:body].matches("I'm really sorry! We're having trouble contacting the EBT system right now.%")).count
    @error_messages_by_week = Message.where(messages[:body].matches("I'm really sorry! We're having trouble contacting the EBT system right now.%")).group_by_week(:date_sent).count
    @successful_messages_by_source = Message.where(messages[:body].matches("Hi! Your food stamp balance is %").or(messages[:body].matches("%El saldo de su cuenta%"))).group(:from_number).count
    @successful_messages_by_source = @successful_messages_by_source.map { |k,v| [@phone_number_hash[k],v] }.sort { |a,b| b[1] <=> a[1] }
  end
end
