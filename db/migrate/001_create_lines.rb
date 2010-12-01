class CreateLines < ActiveRecord::Migration
  def self.up
    create_table :lines do |t|
      t.integer :number
			t.integer :type
			t.string :direction
			t.string :description
    end

		create_table :stops do |t|
			t.integer :line_id
			t.string :name
		end
		
		create_table :plan do |t|
			t.integer :stop_id
			t.integer :type
			t.integer :time
		end
  end

  def self.down
    drop_table :lines
		drop_table :stops
		drop_table :time_table
  end
end