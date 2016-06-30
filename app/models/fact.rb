class Fact < ActiveRecord::Base
  belongs_to :asset
  #has_many :asset, :through => :asset_fact
end
