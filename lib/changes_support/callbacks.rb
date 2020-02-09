module ChangesSupport
  module Callbacks

    def self.included(klass)
      klass.instance_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods

      #
      # on_change_predicate:
      #   Attach a callback to run when the predicate has changed, either it has been added, or
      # it is removed.
      #
      # change_type:
      #    either :addFacts or :removeFacts, depending on the type of change
      # predicate:
      #    predicate value in a fact that we want to watch
      # proc:
      #    callback to run when the change has been applied
      def on_change_predicate(change_type, predicate, proc)
        @changes_callbacks ||= {}
        @changes_callbacks[change_type] ||= {}
        @changes_callbacks[change_type][predicate] ||= []
        @changes_callbacks[change_type][predicate].push(proc)
      end

      def on_keep_predicate(predicate, proc)
        @keep_callbacks ||= {}
        @keep_callbacks[predicate] ||= []
        @keep_callbacks[predicate].push(proc)
      end

      #
      # Resets the callbacks so they won't be run anymore
      def clear_all_callbacks!
        @changes_callbacks = {}
        @keep_callbacks = {}
      end

      def _changes_callbacks
        @changes_callbacks
      end
      def _keep_callbacks
        @keep_callbacks
      end
    end

    module InstanceMethods
      def _changes_callbacks
        self.class._changes_callbacks
      end
      def _on_apply_changes_callbacks(step)
        _changes_callbacks.keys.each do |change_type|
          predicates = _changes_callbacks[change_type].keys
          facts_with_callback = []
          if change_type == 'add_facts'
            facts_with_callback = facts_to_add.select{|f| predicates.include?(f[:predicate])}
          elsif change_type == 'remove_facts'
            facts_with_callback = facts_to_destroy.select{|f| predicates.include?(f[:predicate])}
          end
          facts_with_callback.each do |fact|
            callbacks = _changes_callbacks[change_type][fact[:predicate]]
            callbacks.each do |proc|
              proc.call(fact, self, step)
            end
          end
        end
      end
      def _keep_callbacks
        self.class._keep_callbacks
      end
      def _on_apply_keep_callbacks(step)
        return unless step.asset_group
        _keep_callbacks.keys.each do |predicate|
          Fact.where(asset: step.asset_group.assets, predicate: predicate).each do |fact|
            next if facts_to_destroy.any? do |triple|
              (triple[:asset_id]==fact.asset_id) && (triple[:predicate] == predicate)
            end
            _keep_callbacks[predicate].each do |proc|
              proc.call(fact, self, step)
            end
          end
        end
      end
      def _on_apply(step)
        return unless _changes_callbacks || _keep_callbacks
        _on_apply_changes_callbacks(step)
        _on_apply_keep_callbacks(step)
      end

    end
  end
end
