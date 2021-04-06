Sequel.migration do
  change do
    create_table(:teams) do
      primary_key :id
      String :name
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:users) do
      primary_key :id
      foreign_key :team_id, :teams
      String :name
      String :email, null: false, unique: true
      String :token
      Integer :token_expires_at
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:stages) do
      primary_key :id
      foreign_key :team_id, :teams
      String :name, null: false, unique: true
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:companies) do
      primary_key :id
      String :name, null: false, unique: true
      String :linkedin
      String :notes
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:contacts) do
      primary_key :id
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
      foreign_key :team_id, :teams
      foreign_key :company_id, :companies
      foreign_key :contact_id, :contacts
      foreign_key :assigned_to, :users
      Float :value, null: false, default: Sequel.lit("0.0")
      Integer :closed_at, null: false
      String :notes
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end

    create_table(:deals_stages) do
      primary_key :id
      foreign_key :deal_id, :deals
      foreign_key :stage_id, :stages
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end
  end
end
