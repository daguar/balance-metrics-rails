class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :sid
      t.string :body
      t.string :to_number
      t.string :from_number
      t.string :direction
      t.datetime :date_sent
      t.timestamps
    end
  end
end
