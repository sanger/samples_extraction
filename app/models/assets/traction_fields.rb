module Assets::TractionFields

  def asset_type
    _get_values_for_predicate('a')
  end

  def sample_uuid
    _get_values_for_predicate('sample_tube')
  end

  def study_uuid
    _get_values_for_predicate('study_uuid')
  end

  def pipeline
    _get_values_for_predicate('pipeline')
  end

  def library_type
    _get_values_for_predicate('library_type')
  end

  def estimate_of_gb_required
    _get_values_for_predicate('estimate_of_gb_required')
  end

  def number_of_smrt_cells
    _get_values_for_predicate('number_of_smrt_cells')
  end

  def cost_code
    _get_values_for_predicate('cost_code')
  end

  def _get_values_for_predicate(predicate, &block)
    list = facts.with_predicate(predicate).map do |a|
      if block_given?
        yield a
      else
        a.object_value_or_uuid
      end
    end
    return list[0] if list.length==1
    return nil if list.length == 0
    list
  end

  def fields
    facts.reduce({}) do |memo, f|
      val = f.object_value
      unless val.kind_of? String
        val = val.uuid
      end
      if memo[f.predicate]
        if memo[f.predicate].kind_of?(String)
          memo[f.predicate]=[val]
        else
          memo[f.predicate].push(val)
        end
      else
        memo[f.predicate] = val
      end
      memo
    end
  end
end
