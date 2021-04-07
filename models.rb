require "./db"

Model = Class.new(Sequel::Model(DB))
Model.def_Model(self)

Model.plugin :dataset_associations
Model.plugin :auto_validations, not_null: :presence
Model.plugin :timestamps
Model.plugin :dataset_associations
Model.plugin :string_stripper
Model.plugin :association_proxies

require "./models/team"
require "./models/stage"
require "./models/user"
require "./models/company"
require "./models/deal"
require "./models/contact"

DB.freeze
