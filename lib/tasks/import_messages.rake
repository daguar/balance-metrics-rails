require File.expand_path('../../twilio_importer', __FILE__)

desc 'Imports all messages from Twilio - used by heroku scheduler daily'
task :import_messages => :environment do
  #Imports from scratch each time - @dave should really fix this someday
  TwilioImporter.new.load_messages!
end