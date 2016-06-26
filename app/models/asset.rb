class Asset < ActiveRecord::Base
  has_many :facts, :through => :asset_facts
end
