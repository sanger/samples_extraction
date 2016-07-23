class Fact < ActiveRecord::Base
  belongs_to :asset, :counter_cache => true

  #has_many :asset, :through => :asset_fact
end
