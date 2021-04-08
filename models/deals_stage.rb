class DealsStage < Model
  many_to_one :deal
  many_to_one :stage
end
