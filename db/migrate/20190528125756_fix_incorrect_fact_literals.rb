class FixIncorrectFactLiterals < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.transaction do
      Fact.where(literal: true, object: nil).where.not(object_asset_id: nil).update_all(literal: false)
    end
  end
end
