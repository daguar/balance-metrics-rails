# require File.expand_path('../../twilio_importer', __FILE__)

desc 'Purge all messages from DB that are TO and FROM a Twilio number'
task :purge_bad_messages => :environment do
  puts "Purging bad Twilio messages..."
  client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
  twilio_phone_numbers = client.account.incoming_phone_numbers.list.map { |n| n.phone_number }
  bad_messages = Message.where("to_number IN (?) AND from_number IN (?)", twilio_phone_numbers, twilio_phone_numbers)
  puts "Found #{bad_messages.count} bad messages. Begin destruction..."
  destroyed = bad_messages.destroy_all
  puts "Successfully purged #{destroyed.length} Twilio-to-Twilio messages. Enjoy!"
end