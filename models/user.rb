class User < Model
  plugin :hash_id, salt: ENV.fetch("HASH_ID_SALT").freeze, length: 7

  many_to_one :team
  one_to_many :deals

  def istwo
    1 + 1
  end
end
