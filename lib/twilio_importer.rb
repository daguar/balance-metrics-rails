class TwilioImporter
  def load_messages!
    puts "IMPORTING TWILIO MESSAGES"
    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    messages = client.account.messages.list
    total = messages.total
    count = 0
    while messages.next_page do
      puts "Begin processing messages"
      messages.each do |m|
        if Message.find_by_sid(m.sid) == nil
          Message.create(
            sid: m.sid,
            to_number: m.to,
            from_number: m.from,
            body: m.body,
            direction: m.direction,
            date_sent: m.date_sent ? Time.zone.parse(m.date_sent) : '' # No sent date if the message fails to send
          )
        end
        count += 1
        puts "Processed msg #{count} of #{total}: #{m.sid}"
      end
      messages = messages.next_page
    end
  end
end
