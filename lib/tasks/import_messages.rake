require File.expand_path('../../twilio_helper', __FILE__)

namespace :import do
  desc 'Imports messages from Twilio'
  task :messages do
    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    TwilioHelper
    binding.pry
  end
end
