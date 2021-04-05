Sequel.migration do
  change do
    create_table(:stages) do
      primary_key :id
      String :name, null: false, unique: true
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end
  end
end
