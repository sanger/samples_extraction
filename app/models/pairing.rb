class Pairing
  attr_reader :group, :step_type
  def initialize(params, step_type)
    @step_type = step_type
    @group = params.map do |c_id, barcode|
      { :asset => Asset.find_by_barcode(barcode),
        :condition_group => ConditionGroup.find_by_id(c_id)
      }
    end
  end

  def assets
    @group.pluck(:asset)
  end

  def condition_groups
    @group.pluck(:condition_group)
  end

  def required_condition_groups_compatible?
    ((@step_type.condition_groups - condition_groups).length == 0)
  end

  def group_compatible?
    @group.all?{|obj| obj[:condition_group].compatible_with?(obj[:asset])}
  end

  def all_assets_exist?
    @group.pluck(:asset).all?
  end

  def all_conditions_exist?
    @group.pluck(:condition_group).all?
  end

  def step_type_compatible?
    @step_type.compatible_with?(assets)
  end

  def error_messages
    msgs = []
    msgs.push('Some barcodes were not found') unless all_assets_exist?
    msgs.push('Step requires more types of inputs to work') unless all_conditions_exist?
    msgs.push('Some assets are from a type different from the required') unless group_compatible?
    msgs.push('Assets are not passing the conditions for the step ') unless step_type_compatible?
    msgs.push('Step requires a different set of conditions') unless step_type_compatible?

    msgs.compact.join('. ')
  end

  def valid?
    all_assets_exist? && all_conditions_exist? &&
     group_compatible? && step_type_compatible? && required_condition_groups_compatible?
  end
end
