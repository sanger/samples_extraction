class Fact < ActiveRecord::Base
  belongs_to :asset, :counter_cache => true

  scope :with_predicate, ->(predicate) { where(:predicate => predicate)}

  scope :with_namespace, ->(namespace) { where("predicate LIKE :namespace", namespace: "#{namespace}\#%")}

  scope :for_sequencescape, ->() { with_namespace('SS') }

  #has_many :asset, :through => :asset_fact

  def object_value
    literal? ? object : Asset.find(object_asset_id)
  end

end

