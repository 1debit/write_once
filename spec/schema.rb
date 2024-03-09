ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, :force => true do |t|
    t.integer :account_id, null: false
    t.string :experiment_group, null: false
    t.string :uid

    t.timestamps
  end

  create_table :accounts, :force => true do |t|
    t.timestamps
  end
end