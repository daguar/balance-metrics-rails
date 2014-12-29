class TwilioImporter
  def load_messages!
    puts "IMPORTING TWILIO MESSAGES"
    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    last_message_date = Message.last.date_sent
    date_to_pull = last_message_date - 3.days
    formatted_date = date_to_pull.strftime("%Y-%m-%d")
    messages = client.account.messages.list("DateSent>" => formatted_date)
    total = messages.total
    count = 0
    while messages do
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
      messages = messages.try(:next_page) # returns [] for last page
    end
  end
end