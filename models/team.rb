class Team < Model
  plugin :hash_id, salt: ENV.fetch("HASH_ID_SALT").freeze, length: 7
  plugin :validation_helpers

  one_to_many :stages
  one_to_many :users
  one_to_many :contacts
  one_to_many :companies
  one_to_many :deals

  def validate
    super
    validates_presence [:name, :identifier]
    validates_unique :identifier
  end
end
