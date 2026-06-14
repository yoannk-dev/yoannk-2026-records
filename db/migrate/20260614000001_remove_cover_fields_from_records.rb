class RemoveCoverFieldsFromRecords < ActiveRecord::Migration[8.1]
  def change
    remove_column :records, :cover_bg, :string
    remove_column :records, :cover_fg, :string
    remove_column :records, :cover_motif, :string
  end
end
