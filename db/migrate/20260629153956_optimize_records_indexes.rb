class OptimizeRecordsIndexes < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pg_trgm"

    add_index :records, Arel.sql("LOWER(artist)"),
      name: "index_records_on_lower_artist"

    add_index :records, :artist,
      name: "index_records_on_artist_trgm",
      using: :gin,
      opclass: :gin_trgm_ops

    add_index :records, :title,
      name: "index_records_on_title_trgm",
      using: :gin,
      opclass: :gin_trgm_ops
  end

  def down
    remove_index :records, name: "index_records_on_lower_artist"
    remove_index :records, name: "index_records_on_artist_trgm"
    remove_index :records, name: "index_records_on_title_trgm"
    disable_extension "pg_trgm"
  end
end
