module TwilioService
  extend self

  def get_phone_number_hash
    client = Twilio::REST::Client.new(ENV['TWILIO_BALANCE_PROD_SID'], ENV['TWILIO_BALANCE_PROD_AUTH'])
    phone_number_hash = Hash.new
    list = Array.new
    page = client.account.incoming_phone_numbers.list
    while(page != [])
      page.each { |n| list << n }
      page = page.next_page
    end
    list.each do |number|
      funnel_name = number.friendly_name
      phone_number_hash[number.phone_number] = funnel_name
    end
    phone_number_hash
  end
end
