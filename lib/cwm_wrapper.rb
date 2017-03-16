module CwmWrapper
  class StepExecution
    attr_accessor :step, :asset_group, :original_assets, :created_assets, :facts_to_destroy

    def initialize(params)
      @step = params[:step]
      @asset_group = params[:asset_group]
      @original_assets= params[:original_assets]
      @created_assets= params[:created_assets]
      @facts_to_destroy = params[:facts_to_destroy]
    end


    def run
      input_tempfile = Tempfile.new('datainfer')
      output_tempfile = Tempfile.new('out_datainfer')

      input_tempfile.write(@asset_group.to_n3)
      input_tempfile.write(@step.step_type.to_n3)
      input_tempfile.close
      #`cat #{input_tempfile.path}`
      `/Users/emr/cwm/cwm-1.2.1/cwm #{input_tempfile.path} --base=h --think > #{output_tempfile.path}`

      step_actions = SupportN3::load_step_actions(output_tempfile)

      ['create_asset', 'remove_facts', 'add_facts', 'unselect_asset', 'select_asset'].each do |action_type|
        quads = step_actions[action_type.camelize(:lower).to_sym]
        send(action_type, quads) if quads
      end
    end

    def is_uuid?(str)
      str.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/)
    end

    def fragment(k)
      SupportN3::fragment(k)
    end

    def add_facts(graphs)
      graphs.each do |quads|
        quads.map do |quad|
          asset = Asset.find_by!(:uuid => fragment(quad[0]))
          add_quad_to_asset(quad,asset)
        end
      end
    end

    def remove_facts(graphs)
      graphs.each do |quads|
        quads.map do |quad|
          asset = Asset.find_by!(:uuid => fragment(quad[0]))
          asset.remove_facts(asset.facts.select do |f| 
            return false if f.predicate != fragment(quad[1])

            object = fragment(quad[2])
            if is_uuid?(object)
              return true if f.object_asset == Asset.find_by(:uuid => object)
            else
              return true if f.object == object
            end
          end) do |f|
            asset.add_operations([f], @step, 'removeFacts')
          end
        end
      end
    end

    def add_quad_to_asset(quad, asset, action_type="addFacts")
      object = fragment(quad[2])
      object_asset = nil
      literal = true
      if is_uuid?(object) || quad[2].uri?
        object_asset = Asset.find_by(:uuid => object)
        literal = false if object_asset
      end
      asset.add_facts(Fact.new(:predicate => fragment(quad[1]), :object => object, 
        :object_asset => object_asset, :literal => literal)) do |f|
        asset.add_operations([f], @step, action_type)
      end
    end

    def create_asset(graphs)
      created_assets = {}
      graphs.each do |quads|
        quads.each do |quad|
          created_assets[quad[0]] = [Asset.create!] unless created_assets[quad[0]]
          @step.asset_group.add_assets(created_assets[quad[0]])
          created_assets[quad[0]].each do |asset|
            add_quad_to_asset(quad, asset, "createAsset")
          end
        end
      end
    end

    def select_asset(assets, quads)
      @step.asset_group.add_assets(assets)
    end

    def unselect_asset(assets, quads)
      @step.asset_group.remove_assets(assets)
    end
  end
end