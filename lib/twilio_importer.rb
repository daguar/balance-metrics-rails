require File.expand_path('../twilio_helper', __FILE__)

class TwilioImporter
  def load_messages!
    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    all_messages = TwilioHelper.process_multipage_list(client.account.messages.list)
    count = all_messages.count
    all_messages.each_with_index do |m, index|
      if Message.find_by_sid(m.sid) == nil
        Message.create(
          sid: m.sid,
          to: m.to,
          from: m.from,
          body: m.body,
          direction: m.direction,
          date_sent: Time.zone.parse(m.date_sent)
        )
      end
      puts "Processed #{index} of #{count} (#{m.sid})"
    end
  end
end
