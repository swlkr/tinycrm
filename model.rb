DB ||= Sequel.sqlite ENV.fetch("DATABASE_URL", "db.sqlite3")

Model = Class.new(Sequel::Model(DB))
Model.def_Model(self)

Model.plugin :dataset_associations
Model.plugin :auto_validations, not_null: :presence
Model.plugin :timestamps
Model.plugin :dataset_associations
Model.plugin :string_stripper
Model.plugin :association_proxies

DB.freeze
