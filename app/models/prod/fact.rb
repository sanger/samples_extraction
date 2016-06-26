class Prod::Fact < ActiveRecord::Base
  has_many :asset, :through => :asset_fact
end
