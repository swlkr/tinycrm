Sequel.migration do
  change do
    alter_table :teams  do
      add_column :identifier, String
      add_index :identifier, unique: true
    end
  end
end
