require 'inference_engines/default/actions/asset_actions'
require 'inference_engines/default/actions/fact_actions'
require 'inference_engines/default/actions/service_actions'

module InferenceEngines
  module Default
    class StepExecution
      include Actions::AssetActions
      include Actions::FactActions
      include Actions::ServiceActions

      # Elements not modified during all lifetime of StepExecution instance
      attr_accessor :step
      attr_accessor :asset_group
      attr_accessor :original_assets

      # Elements not modified during execution of one action
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
      # Hash with the positions for each asset by condition group
      attr_accessor :positions_for_asset

      attr_accessor :updates

      ACTION_TYPES = ['addFacts', 'removeFacts', 'createAsset', 'selectAsset', 'updateService']

      def initialize(params)
        @step = params[:step]
        @asset_group = params[:asset_group]
        @original_assets= params[:original_assets]
        @created_assets= params[:created_assets]
        @facts_to_destroy = params[:facts_to_destroy]
        @updates = FactChanges.new
      end

      def valid_action_type?
        ACTION_TYPES.include?(action.action_type)
      end

      def asset_group_assets
        asset_group ? asset_group.assets : []
      end

      def executable_actions_sorted
        step.step_type.actions.includes([:subject_condition_group, :object_condition_group]).sort do |a,b|
          [:create_asset, :add_facts, :remove_facts, :delete_asset, :select_asset, :unselect_asset]
          if a.action_type=='createAsset'
            -1
          elsif b.action_type=='createAsset'
            1
          else
            a.action_type <=> b.action_type
          end
        end
      end


      # Identifies which asset acting as subject is compatible with which rule.
      def each_sorted_executable_action_with_applicable_assets(&block)
        # Classifies every asset in the asset group with every condition group, returning an object with
        # { asset_id => { condition_group_id => position}}
        @positions_for_asset = step.step_type.position_for_assets_by_condition_group(asset_group_assets)
        executable_actions_sorted.each do |executable_action|
          if executable_action.subject_condition_group.nil?
            raise Steps::ExecutionErrors::RelationSubject, 'A subject condition group needs to be specified to apply the rule'
          end

          executable_action.run(asset_group_assets)

          yield [executable_action]
          # If this condition group is referring to an element not matched (like
          # a new created asset, for example) I cannot classify any assets with it, so I run it as it is
          if (!step.step_type.condition_groups.include?(executable_action.subject_condition_group))
            yield [executable_action, nil, nil]
          else
            asset_group_assets.includes(:facts).each do |asset|
              if executable_action.subject_condition_group.compatible_with?(asset)
                yield [executable_action, asset, positions_for_asset[asset.id][executable_action.subject_condition_group.id]]
              end
            end
          end
        end
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
      end

      def run
        updates = executable_actions_sorted.reduce(FactChanges.new) do |updates, action|
          action.run(asset_group, @step.wildcard_values).merge(updates)
        end
        save_created_assets
        updates.apply(step)
        step_type.condition_groups.each do |cg|
          if cg.keep_selected != true
            assets = asset_group.classified_by_condition_group(subject_condition_group)
            assets.each do |asset|
              asset_group.assets.delete(asset)
            end
          end
        end
      end

    end
  end
end
