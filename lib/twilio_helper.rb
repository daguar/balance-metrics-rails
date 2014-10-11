module TwilioHelper
  extend self

  def process_multipage_list(list, return_array = Array.new)
    list.each do |item|
      return_array << item
    end
    if list.next_page != []
      process_multipage_list(list.next_page, return_array)
    else
      return return_array
    end
  end
end
