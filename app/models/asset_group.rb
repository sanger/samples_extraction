class AssetGroup < ActiveRecord::Base
  has_and_belongs_to_many :assets, ->() {uniq}
  has_many :steps
  has_one :activity

  belongs_to :activity_owner, :class_name => 'Activity'
  belongs_to :condition_group, :class_name => 'ConditionGroup'

  include Printables::Group


  def condition_group_name
    prefix = condition_group.nil? ? "Main" : condition_group.name
    "#{prefix} #{id}"
  end

  def last_update
    [updated_at, assets.map(&:updated_at)].flatten.max
  end

  def add_assets(list)
    list = [list].flatten
    list.each do |asset|
      assets << asset unless has_asset?(asset)
    end
  end

  def has_asset?(asset)
    assets.include?(asset)
  end

  def select_barcodes(barcodes)
    barcodes.each do |barcode|
      if assets.select{|a| a.barcode == barcode}.empty?
        asset = Asset.find_or_import_asset_with_barcode(barcode)
        return false if asset.nil?
        add_assets(asset)
      end
    end
    return true
  end

  def unselect_barcodes(barcodes)
    barcodes.each do |barcode|
      selection = assets.select{|a| (a.barcode == barcode) || (a.uuid == barcode)}
      assets.delete(selection)
    end
  end

  def unselect_all_barcodes
    assets.delete(assets)
  end

  def unselect_assets_with_conditions(condition_groups)
    condition_groups.each do |condition_group|
      unless condition_group.keep_selected
        unselect_assets = assets.includes(:facts).select do |asset|
          condition_group.compatible_with?(asset)
        end
        assets.delete(unselect_assets) if unselect_assets
      end
    end
  end

  def to_n3
    assets.map(&:to_n3).join('')
  end

end
