class Asset < ActiveRecord::Base
  has_many :steps
  has_many :asset_facts
  has_many :facts, :through => :asset_facts, :class_name => 'Fact'
end
