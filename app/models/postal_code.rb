class PostalCode < ApplicationRecord

  scope :with_code, -> (code) { where(code: code) }

  def self.with_code_hint(code_hint)
    where('code LIKE :prefix', prefix: "#{code_hint}%")
        .order(code: :asc)
        .distinct
        .pluck(:code)
  end

  def self.get_suburbs_for(code)
    with_code(code).pluck(:colony)
  end

  def self.get_shared_data_for(code)
    with_code(code).limit(1).pluck(:municipality, :state)
  end

end
