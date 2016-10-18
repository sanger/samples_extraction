class Fact < ActiveRecord::Base
  belongs_to :asset, :counter_cache => true
  belongs_to :object_asset, :class_name => 'Asset'


  scope :with_predicate, ->(predicate) { where(:predicate => predicate)}

  scope :with_fact, -> (predicate, object) { where(:predicate => predicate, :object => object)}

  scope :with_namespace, ->(namespace) { where("predicate LIKE :namespace", namespace: "#{namespace}\#%")}

  scope :for_sequencescape, ->() { with_namespace('SS') }


  def object_value
    literal? ? object : Asset.find(object_asset_id)
  end

  def object_label
    return object unless object_asset
    "#{object_asset.asset_description} #{object_asset.barcode.blank? ? '#' : Asset.find(object_asset_id).barcode}"
  end

end

