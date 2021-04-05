Sequel.migration do
  change do
    create_table(:chances) do
      primary_key :id
      foreign_key :company_id, :companies
      foreign_key :assigned_to, :users
      Float :value, null: false, default: Sequel.lit("0.0")
      Integer :closed_at, null: false
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end
  end
end
