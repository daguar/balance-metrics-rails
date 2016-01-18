class IncomingController < ApplicationController
  http_basic_authenticate_with name: ENV['BALANCE_METRICS_USERNAME'], password: ENV['BALANCE_METRICS_PASSWORD']

  def index
    @phone_number_hash = TwilioService.get_phone_number_hash

    @all_inbound_messages = Message.where("direction = ?", "inbound").order("date_sent ASC").paginate(:page => params[:page], :per_page => 200)
  end
end
