class Fact < ActiveRecord::Base
  belongs_to :asset, :counter_cache => true
  belongs_to :object_asset, :class_name => 'Asset'


  scope :with_predicate, ->(predicate) { where(:predicate => predicate)}

  scope :with_namespace, ->(namespace) { where("predicate LIKE :namespace", namespace: "#{namespace}\#%")}

  scope :for_sequencescape, ->() { with_namespace('SS') }


  def object_value
    literal? ? object : Asset.find(object_asset_id)
  end

end

