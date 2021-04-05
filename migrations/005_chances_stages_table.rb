Sequel.migration do
  change do
    create_table(:chances_stages) do
      primary_key :id
      foreign_key :chance_id, :chances
      foreign_key :stage_id, :stages
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end
  end
end
