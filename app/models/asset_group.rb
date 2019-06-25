
class AssetGroup < ActiveRecord::Base
  include Uuidable

  has_many :asset_groups_assets, dependent: :destroy
  has_many :assets, through: :asset_groups_assets
  #has_and_belongs_to_many :assets, ->() {distinct}
  has_many :steps
  has_many :uploaded_files, through: :assets

  has_one :activity, dependent: :nullify
  belongs_to :activity_owner, :class_name => 'Activity'
  belongs_to :condition_group, :class_name => 'ConditionGroup'

  alias_method :activity, :activity_owner

  include Printables::Group

  after_touch :touch_activity

  def refresh
    assets.each(&:refresh)
  end

  def update_with_assets(assets_to_update)
    removed_assets = self.assets - assets_to_update
    added_assets = assets_to_update - self.assets

    if ((removed_assets.length > 0) || (added_assets.length > 0))
      updates = FactChanges.new
      updates.add_assets([[self, added_assets]]) if added_assets
      updates.remove_assets([[self, removed_assets]]) if removed_assets

      ActiveRecord::Base.transaction do
        step = Step.create(activity: activity_owner, asset_group: self,
          in_progress?: true, state: 'complete', step_type: step_type_for_import)
        updates.apply(step)
      end
    end
    touch
  end

  def step_type_for_import
    @step_type_for_import ||= StepType.find_or_create_by(name: 'ChangeGroup')
  end

  def position_for_asset(asset)
    assets.each_with_index{|a, pos| return pos if (asset.id == a.id)}
    return -1
  end

  def touch_activity
    if activity_owner
      activity_owner.touch
    end
  end

  def classified_by_condition_group(condition_group)
    @classification ||= {}
    if (condition_group.conditions.length == 0)
      @classification[condition_group.id] ||= []
    else
      @classification[condition_group.id] ||= condition_group.select_compatible_assets(assets)
    end
  end

  def classify_assets_in_condition_group(assets, condition_group)
    @classification ||= {}
    @classification[condition_group.id] ||= []
    @classification[condition_group.id] = @classification[condition_group.id].concat(assets)
  end

  def condition_group_name
    prefix = condition_group.nil? ? "Main" : condition_group.name
    "#{prefix} #{id}"
  end

  def display_name
    prefix = name || "Main"
    "#{prefix} #{id}"
  end

  def last_update
    [updated_at, assets.map(&:updated_at)].flatten.max
  end

  def add_assets(list_to_add)
    assets_to_add = list_to_add - assets
    assets << assets_to_add
  end

  def remove_assets(list)
    unselect_barcodes(list.map(&:uuid))
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

  def to_n3
    render :n3
  end

  def clean_fact_group(groups)
    h = {}
    groups.each do |group, assets|
      h[group] = assets.uniq
    end
    h
  end

  def assets_by_fact_group
    return [] unless assets
    obj_type = Struct.new(:predicate,:object, :to_add_by, :to_remove_by, :object_asset_id)

    groups = assets.group_by do |a|
      a.facts.sort do |f1,f2|
        # Canonical sort of facts
        f1.canonical_comparison_for_sorting(f2)
      end.map(&:as_json).map do |f|
        obj = f["object"]
        if f["object_asset_id"]
          obj="?"
        end
        obj_type.new(f["predicate"], obj, f["to_add_by"], f["to_remove_by"], nil)
      end.uniq
    end

    clean_fact_group(groups)
  end

end
