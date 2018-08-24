require 'step_execution_process'
require 'open3'

module InferenceEngines
  module Cwm
    class StepExecution
      include StepExecutionProcess
      
      attr_accessor :step, :asset_group, :original_assets, :created_assets, :facts_to_destroy, :updates

      def initialize(params)
        @step = params[:step]
        @asset_group = params[:asset_group]
        @original_assets= params[:original_assets]
        @created_assets= params[:created_assets]
        @facts_to_destroy = params[:facts_to_destroy]

        @step_types = params[:step_types] || [@step.step_type]
        @updates = FactChanges.new
      end

      def debug_log(params)
        puts params
        if Rails.logger
          Rails.logger.debug(params)
        else
          @log = Logger.new(STDOUT) unless @log
          @log.debug(params)
        end
      end

      def generate_plan
        output_tempfile = Tempfile.new('out_datainfer')
        call_list = [
          cmd = "#{Rails.configuration.cwm_path}/cwm",
          input_urls = [
            Rails.application.routes.url_helpers.asset_group_url(@asset_group.id),
            @step_types.map do |step_type|
              Rails.application.routes.url_helpers.step_type_url(step_type.id)
            end
          ],
          '--mode=r', 
          '--think'
        ].flatten
        
        call_str = call_list.join(" ")

        line = "# EXECUTING: #{call_str}"

        proxy = Rails.configuration.cwm_proxy
        env_vars = {'http_proxy' => proxy, 'https_proxy' => proxy}

        Open3.popen3(*[env_vars, call_list].flatten) do |stdin, stdout, stderror, thr|
          content = stdout.read
          output = [line, content].join("\n")
          step.update_attributes(output: output)
          unless thr.value==0
            raise "cwm execution failed\nCODE: #{thr.value}\nCMD: #{line}\nSTDOUT: #{content}\nSTDERR: #{stderror.read}\n"
          end
        end
      end

      def inference
        generate_plan

        debug_log step.output
      end

      def refresh
        @asset_group.assets.each(&:refresh)
      end

      def export
        step_actions = SupportN3::load_step_actions(step.output)

        ['create_asset', 'remove_facts', 'add_facts', 'unselect_asset', 'select_asset'].each do |action_type|
          quads = step_actions[action_type.camelize(:lower).to_sym]
          send(action_type, quads) if quads
        end

        updates.apply(step)
        
      end

      def self.UUID_REGEXP
        /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      end

      def is_uuid?(str)
        str.match(self.class.UUID_REGEXP)
      end

      def uuid(str)
        str.match(self.class.UUID_REGEXP)[0]
      end

      def fragment(k)
        SupportN3::fragment(k)
      end

      def add_facts(graphs)
        graphs.each do |quads|
          quads.map do |quad|
            asset = Asset.find_by!(:uuid => uuid(fragment(quad[0])))
            add_quad_to_asset(quad,asset)
          end
        end
      end

      def equal_quad_and_fact?(quad, fact)
        return false if fact.predicate != fragment(quad[1])
        object = fragment(quad[2])
        if is_uuid?(object)
          return true if fact.object_asset == Asset.find_by(:uuid => uuid(object))
        else
          return true if fact.object == object
        end
        return false
      end

      def remove_facts(graphs)
        graphs.each do |quads|
          quads.map do |quad|
            asset = Asset.find_by!(:uuid => uuid(fragment(quad[0])))
            updates.remove(asset.facts.select {|f| equal_quad_and_fact?(quad, f) })
          end
        end
      end

      def add_quad_to_asset(quad, asset, action_type="addFacts")
        object = fragment(quad[2])
        object_asset = nil
        literal = true
        if is_uuid?(object)
          object_asset = Asset.find_by(:uuid => uuid(object))
          literal = false if object_asset
        end
        updates.add(asset, fragment(quad[1]), object || object_asset)
      end

      def create_asset(graphs)
        if @step.created_asset_group.nil?
          @step.created_asset_group = AssetGroup.create(:activity_owner => @step.activity)
        end
        created_assets = {}
        graphs.each do |quads|
          quads.each do |quad|
            created_assets[quad[0]] = [ Asset.create! ].flatten unless created_assets[quad[0]]
            @step.asset_group.add_assets(created_assets[quad[0]])
            created_assets[quad[0]].each do |asset|
              add_quad_to_asset(quad, asset, "createAsset")
            end
          end
        end
        @step.created_asset_group.add_assets(created_assets.values.flatten.compact.uniq)
      end

      def select_asset(assets, quads)
        @step.asset_group.add_assets(assets)
      end

      def unselect_asset(assets, quads)
        @step.asset_group.remove_assets(assets)
      end
    end
  end
end