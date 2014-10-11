class Message < ActiveRecord::Base
  attr_accessible :sid, :body, :to, :from, :direction, :date_sent
end
