class StepExecution
  include StepExecution::AssetActions
  include StepExecution::FactActions
  include StepExecution::OperationActions
  include StepExecution::ServiceActions

  # Elements not modified during all lifetime of StepExecution instance
  attr_accessor :step
  attr_accessor :asset_group
  attr_accessor :original_assets

  # Elements not modified during 1 execution
  attr_accessor :asset
  attr_accessor :position
  attr_accessor :action

  # Elements modified in every execution:

  # Assets that have changed in this execution
  attr_accessor :changed_assets
  # Facts modified for the changed assets
  attr_accessor :changed_facts
  # Assets created during all the executions
  attr_accessor :created_assets
  # List of facts that will be destroyed in a single DELETE sql
  attr_accessor :facts_to_destroy

  ACTION_TYPES = ['addFacts', 'removeFacts', 'createAsset', 'selectAsset', 'updateService']

  def initialize(params)
    @step = params[:step]
    @asset_group = params[:asset_group]
    @original_assets= params[:original_assets]
    @created_assets= params[:created_assets]
    @facts_to_destroy = params[:facts_to_destroy]
  end

  def valid_action_type?
    ACTION_TYPES.include?(action.action_type)
  end

  def perform_action(action, asset, position)
    @asset = asset
    @position = position
    @action = action

    @changed_assets= [asset]
    @changed_facts = nil
    if action.subject_condition_group.conditions.empty?
      @changed_assets= created_assets[action.subject_condition_group.id]
    end

    if valid_action_type?
      send(action.action_type.underscore)
    end
    store_operations
  end

end
