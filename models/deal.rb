class Deal < Model
  plugin :hash_id, salt: ENV.fetch("HASH_ID_SALT").freeze, length: 7

  many_to_one :team
  many_to_one :company
  many_to_one :contact
  many_to_one :user

  many_to_many :stages

  def latest_stage
    deal_stage = DealsStage.where(deal: self).order(:created_at).last
    Stage.find(id: deal_stage.stage_id)
  end
end
