class CreateRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :records do |t|
      t.string :artist, null: false
      t.string :title, null: false
      t.references :label, null: true, foreign_key: true
      t.integer :year
      t.string :format
      t.string :genre
      t.string :country
      t.string :catalog_number
      t.string :cover_image_url
      t.string :cover_bg
      t.string :cover_fg
      t.string :cover_motif
      t.jsonb :tracklist
      t.string :discogs_id
      t.string :barcode

      t.timestamps
    end

    add_index :records, :discogs_id, unique: true, where: "discogs_id IS NOT NULL"
    add_index :records, :genre
  end
end
