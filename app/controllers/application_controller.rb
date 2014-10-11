class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def index
    messages = Message.arel_table
    @successful_messages = Message.where(messages[:body].matches("Hi! Your food stamp balance is%").or(messages[:body].matches("El saldo de su cuenta"))).count
  end
end
