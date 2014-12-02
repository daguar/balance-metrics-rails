class InternalController < ApplicationController
  http_basic_authenticate_with name: ENV['BALANCE_METRICS_USERNAME'], password: ENV['BALANCE_METRICS_PASSWORD']

  def index
  end
end
