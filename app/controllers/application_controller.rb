class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    messages = Message.arel_table
    @count_of_successful_messages = Message.where(messages[:body].matches("Hi! Your food stamp balance is%").or(messages[:body].matches("%El saldo de su cuenta%"))).count
    @successful_messages_by_week = Message.where(messages[:body].matches("Hi! Your food stamp balance is%").or(messages[:body].matches("%El saldo de su cuenta%"))).group_by_week(:date_sent).count
    @count_of_error_messages = Message.where(messages[:body].matches("I'm really sorry! We're having trouble contacting the EBT system right now.%")).count
    @error_messages_by_week = Message.where(messages[:body].matches("I'm really sorry! We're having trouble contacting the EBT system right now.%")).group_by_week(:date_sent).count
  end
end
