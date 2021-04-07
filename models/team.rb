class Team < Model
  plugin :hash_id, salt: ENV.fetch("HASH_ID_SALT").freeze, length: 7

  one_to_many :stages
  one_to_many :users
  one_to_many :contacts
  one_to_many :companies
end
