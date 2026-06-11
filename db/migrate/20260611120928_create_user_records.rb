class CreateUserRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :user_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :record, null: false, foreign_key: true
      t.string :condition
      t.datetime :added_at

      t.timestamps
    end

    add_index :user_records, [ :user_id, :record_id ], unique: true
  end
end
