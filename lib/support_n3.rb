module SupportN3
  def self.fragment(k)
    k.try(:fragment) || k.name.to_s.gsub(/.*#/,'')
  end

  def self.step_type(quads)
    names = quads.select{|quad| fragment(quad[1]) == 'stepTypeName'}.flatten
    return StepType.find_or_create_by(:name => names[2].to_s) unless names.empty?
    return StepType.create(:name => "Rule from #{DateTime.now.to_s}")
  end

  def self.load_n3(file_path)
    RDF::N3::Reader.open(file_path) do |reader|
      quads = reader.quads
      rules = quads.select{|quad| fragment(quad[1])=='implies'}
      rules.each do |k,p,v,g|
        conditions = quads.select{|quad| quad.last === k}
        actions = quads.select{|quad| quad.last === v}

        step_type = step_type(actions)
        step_type.activity_types << ActivityType.last

        c_groups = {}
        conditions.each do |k,p,v,g|
          fr = fragment(k)
          if c_groups.keys.include?(fr)
            condition_group = c_groups[fr]
          else
            condition_group = ConditionGroup.create(:step_type => step_type)
            c_groups[fr] = condition_group
          end
          Condition.create({ :predicate => fragment(p), :object => fragment(v),
            :condition_group_id => condition_group.id})
        end

        actions.each do |k,p,v,g|
          action = fragment(p)
          unless v.literal?
            quads.select{|quad| quad.last == v}.each do |k,p,v,g|
              Action.create({:action_type => action, :predicate => fragment(p),
                :object => fragment(v),
                :step_type_id => step_type.id,
                :condition_group_id => c_groups[fragment(k)].id})
            end
          end
        end
      end
    end
  end
end
