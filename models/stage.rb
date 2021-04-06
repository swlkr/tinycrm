class Stage < Sequel::Model
  many_to_one :team

  def validate
    super

    if name&.empty?
      errors.add(:name, 'can\'t be blank')
    end
  end
end

