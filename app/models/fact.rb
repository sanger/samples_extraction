class Fact < ActiveRecord::Base
  belongs_to :asset, :counter_cache => true

  scope :with_predicate, ->(predicate) { where(:predicate => predicate)}

  #has_many :asset, :through => :asset_fact
end
