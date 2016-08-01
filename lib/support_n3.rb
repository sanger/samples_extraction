module SupportN3
  def self.parse_string(input, options = {}, step_type)
    options = {
      validate: false,
      canonicalize: false,
    }.merge(options)
    RuleGraphAccessor.parse_rules(RDF::N3::Reader.new(input, options).quads, step_type)
  end

  def self.parse_file(file_path)
    RDF::N3::Reader.open(file_path) do |reader|
      RuleGraphAccessor.parse_rules(reader.quads)
    end
  end

  class RuleGraphAccessor
    attr_reader :quads
    attr_reader :graph_conditions
    attr_reader :graph_consequences
    attr_reader :c_groups
    attr_reader :c_groups_cardinalities

    attr_reader :conditions
    attr_reader :actions

    attr_reader :step_type

    def self.rules(quads)
      quads.select{|quad| fragment(quad[1])=='implies'}
    end

    def self.parse_rules(quads, enforce_step_type=nil)
      RuleGraphAccessor.rules(quads).each do |k,p,v,g|
        accessor = RuleGraphAccessor.new(enforce_step_type, quads, k, v)
        accessor.execute
      end
    end

    def initialize(step_type, quads, graph_conditions, graph_consequences)
      @quads = quads
      @graph_conditions = graph_conditions
      @graph_consequences = graph_consequences
      @c_groups = {}
      @c_groups_cardinalities={}

      @step_type = step_type || config_step_type
    end

    def conditions
      @conditions ||= @quads.select{|quad| quad.last === @graph_conditions}
    end

    def actions
      @actions ||= sort_created_assets_first(@quads.select do |quad|
        quad.last === @graph_consequences
      end)
    end

    def sort_created_assets_first(list)
      list.sort do |a,b|
        if fragment(a[1])=='createAsset'
          -1
        elsif fragment(b[1])=='createAsset'
          1
        else
          fragment(a[1]) <=> fragment(b[1])
        end
      end
    end

    def fragment(k)
      k.try(:fragment) || (k.try(:name) || k).to_s.gsub(/.*#/,'')
    end

    def self.fragment(k)
      k.try(:fragment) || (k.try(:name) || k).to_s.gsub(/.*#/,'')
    end


    def condition_group_for(node)
      c_groups[fragment(node)]
    end

    def store_condition_group(condition_group)
      c_groups[condition_group.name]=condition_group
    end


    def find_or_create_condition_group_for(node, params)
      if condition_group_for(node)
        condition_group_for(node)
      else
        params[:name] = fragment(fragment(node))
        store_condition_group(ConditionGroup.create(params))
      end
    end

    def keep_selected_list
      actions.select{|quad| fragment(quad[1]) == 'unselectAsset'}.map do |q|
        if q[2].class == RDF::Node
          fragment(@quads.select{|k,p,v,g| g==q[2]}.flatten[0])
        else
          fragment(q[2])
        end
      end.flatten
    end

    def check_keep_selected_asset(node)
      list = keep_selected_list
      !list.include?(fragment(node))
    end

    def update_condition_group(condition_group, p, v)
      if fragment(p) == 'maxCardinality'
        # Once we have the condition group, we update cardinality
        @c_groups_cardinalities[fragment(p)] = fragment(v)
        condition_group.update_attributes(:cardinality => fragment(v))
      else
        # or we add the new condition
        Condition.create({ :predicate => fragment(p), :object => fragment(v),
        :condition_group_id => condition_group.id})
      end
    end

    def build_condition_groups
      # Left side of the rule
      conditions.each do |k,p,v,g|
        # Finds the condition group (or creates it)
        condition_group = find_or_create_condition_group_for(k,
          {:step_type => @step_type,
          :keep_selected => check_keep_selected_asset(k)})
        update_condition_group(condition_group, p, v)
      end
    end

    def activity_type
      name = @quads.select{|quad| fragment(quad[1]) == 'activityTypeName'}.flatten[2].to_s
      return ActivityType.find_by({ :name => name, :superceded_by_id => nil })
    end

    def config_step_type
      names = actions.select{|quad| fragment(quad[1]) == 'stepTypeName'}.flatten
      if !names.empty?
        @step_type = StepType.find_or_create_by(:name => names[2].to_s)
      else
        @step_type = StepType.create(:name => "Rule from #{DateTime.now.to_s}")
      end

      @step_type.update_attributes(:step_template => step_template) if step_template
      @step_type.activity_types << activity_type if activity_type
      @step_type
    end

    def step_template
      value = actions.select{|quad| fragment(quad[1]) == 'stepTemplate'}.flatten[2]
      fragment(value) unless value.nil?
    end


    def execute
      build_condition_groups
      build_actions
    end

    def build_actions
      # Right side of the rule
      actions.each do |k,p,v,g|
        action = fragment(p)
        unless v.literal?
          @quads.select{|quad| quad.last == v}.each do |k,p,v,g|
            # Updates cardinality for the condition group
            if fragment(p) == 'maxCardinality'
              @c_groups_cardinalities[fragment(k)] = fragment(v)
              if @c_groups[fragment(k)]
                @c_groups[fragment(k)].update_attributes(:cardinality => @c_groups_cardinalities[fragment(k)])
              end
              next
            end

            # Creates condition groups from the subjects of the actions
            # side of the rules
            if @c_groups[fragment(k)].nil?
              @c_groups[fragment(k)] = ConditionGroup.create({:cardinality => @c_groups_cardinalities[fragment(k)],
                :name => fragment(k), :keep_selected => check_keep_selected_asset(fragment(k))})
            end
            # Creates condition groups from the objects of the actions side
            object_condition_group_id = nil
            if c_groups[fragment(v)]
              object_condition_group_id = c_groups[fragment(v)].id
            else
              if v.class.name == 'RDF::Query::Variable'
                if c_groups[fragment(v)].nil?
                  c_groups[fragment(v)] = ConditionGroup.create(:cardinality => @c_groups_cardinalities[fragment(v)],
                    :name=> fragment(v), :keep_selected => check_keep_selected_asset(fragment(v)))
                end
                object_condition_group_id = c_groups[fragment(v)].id
              end
            end
            Action.create({:action_type => action, :predicate => fragment(p),
              :object => fragment(v),
              :step_type_id => @step_type.id,
              :subject_condition_group_id => @c_groups[fragment(k)].id,
              :object_condition_group_id => object_condition_group_id
            })
            if (action=='unselectAsset')
              Condition.create({
                :predicate => fragment(p), :object => fragment(v),
                :condition_group_id =>  @c_groups[fragment(k)].id})
            end
          end
        end
      end
    end
  end
end
