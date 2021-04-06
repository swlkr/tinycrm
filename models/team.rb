class Team < Sequel::Model
  one_to_many :stages
end
