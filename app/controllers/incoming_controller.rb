class IncomingController < ApplicationController
  http_basic_authenticate_with name: ENV['BALANCE_METRICS_USERNAME'], password: ENV['BALANCE_METRICS_PASSWORD']

  def index
    # client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    # @phone_number_hash = Hash.new
    # client.account.incoming_phone_numbers.list.each do |number|
    #   funnel_name = number.friendly_name
    #   @phone_number_hash[number.phone_number] = funnel_name
    # end

    # @all_inbound_messages = Message.find_all_by_direction("inbound")
  end
end
