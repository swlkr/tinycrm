Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :name
      String :email, null: false, unique: true
      String :token
      Integer :token_expires_at
      Integer :updated_at
      Integer :created_at, null: false, default: Sequel.lit("strftime('%s', 'now')")
    end
  end
end
