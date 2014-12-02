class InternalController < ApplicationController
  http_basic_authenticate_with name: ENV['BALANCE_METRICS_USERNAME'], password: ENV['BALANCE_METRICS_PASSWORD']

  def index
  end

  def phone_number
    @phone_number = params[:number]
    number_for_sql = '+' + @phone_number
    m = Message.arel_table
    @messages = Message.where(m[:to_number].eq(number_for_sql).or(m[:from_number].eq(number_for_sql))).order('date_sent ASC')
  end
end
