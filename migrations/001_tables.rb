Sequel.migration do
  change do
    create_table(:teams) do
      primary_key :id
      String :name, null: false
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:users) do
      primary_key :id
      foreign_key :team_id, :teams, on_delete: :cascade
      String :name
      String :email, null: false, unique: true
      String :token
      Integer :token_expires_at
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:stages) do
      primary_key :id
      foreign_key :team_id, :teams, on_delete: :cascade
      String :name, null: false, unique: true
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:companies) do
      primary_key :id
      foreign_key :team_id, :teams, on_delete: :cascade
      String :name, null: false
      String :linkedin
      String :url
      String :notes
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:contacts) do
      primary_key :id
      foreign_key :team_id, :teams, on_delete: :cascade
      foreign_key :company_id, :companies, on_delete: :cascade
      String :name
      String :email
      String :address
      String :phone
      String :linkedin
      String :notes
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:deals) do
      primary_key :id
      foreign_key :team_id, :teams, on_delete: :cascade
      foreign_key :company_id, :companies, on_delete: :set_null
      foreign_key :contact_id, :contacts, on_delete: :set_null
      foreign_key :user_id, :users, on_delete: :set_null
      foreign_key :stage_id, :stages, on_delete: :set_null
      Float :value, null: false, default: Sequel.lit("0.0")
      Integer :closed_at
      String :notes
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end
  end
end
