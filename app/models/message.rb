class Message < ActiveRecord::Base
  attr_accessible :sid, :body, :to_number, :from_number, :direction, :date_sent
end
