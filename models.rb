require "./db"

Model = Class.new(Sequel::Model)
Model.db = DB
Model.def_Model(self)

Model.plugin :auto_validations, not_null: :presence

require "./models/team"
require "./models/stage"

DB.freeze
