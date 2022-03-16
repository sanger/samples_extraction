module ApplicationHelper
  def unknown_aliquot_type
    'unknown-aliquot'
  end

  def empty_well_aliquot_type
    'empty-well-aliquot'
  end

  def bootstrap_link_to(name = nil, options = nil, html_options = nil, &block)
    modified_options = { :class => 'btn btn-default' }
    modified_options.merge!(html_options) if html_options
    link_to(name, options, modified_options)
  end

  def default_ontologies
    [
      "@prefix se: <#{n3_url_for_ontology('root-ontology.ttl')}#> .",
      "@prefix log: <http://www.w3.org/2000/10/swap/log#> ."
    ].join("\n").html_safe
  end

  def n3_url_for_ontology(name)
    url_definition = Rails.configuration.default_n3_resources_url
    if url_definition
      "#{url_definition}#{path_to_asset(name)}"
    else
      "#{url_to_asset(name)}"
    end
  end

  def n3_url_resource_for(asset_uuid)
    url_definition = Rails.configuration.default_n3_resources_url
    if url_definition
      "#{url_definition}/labware/#{asset_uuid}"
    else
      asset_url(asset_uuid)
    end
  end

  def traversable_predicate(predicate)
    ['contains'].include?(predicate)
  end

  def object_for(fact)
    if fact.object_asset.nil?
      if fact.literal?
        "\"\"\"#{fact.object}\"\"\"".html_safe
      else
        "se:#{fact.object}".html_safe
      end
    else
      "<#{n3_url_resource_for(fact.object_asset.uuid)}>".html_safe
    end
  end

  def render_react_display_for_asset(asset)
    data_asset_display = {}.tap { |o| o[asset.uuid] = data_asset_display(asset.facts) }
    react_component('FactsSvg', { asset: asset, facts: facts_with_object_asset(asset.facts), dataAssetDisplay: data_asset_display })
  end

  def render_react_tooltip
    react_component('ReactTooltip', { multiline: true, effect: 'solid' })
  end

  def facts_with_object_asset(facts)
    facts.left_outer_joins(:object_asset).to_a.map { |f| f.attributes.merge({ object_asset: object_with_facts(f.object_asset) }) }
  end

  def object_with_facts(object)
    return nil if object.nil?

    object.attributes.merge(facts: object.facts)
  end

  def render_react_display_and_facts_for_asset(asset)
    data_asset_display = {}.tap { |o| o[asset.uuid] = data_asset_display(asset.facts) }
    react_component('Facts', { asset: asset, facts: facts_with_object_asset(asset.facts), dataAssetDisplay: data_asset_display })
  end

  def render_react_edit_asset(asset, readonly = false)
    data_asset_display = {}.tap { |o| o[asset.uuid] = data_asset_display(asset.facts) }
    react_component('FactsEditor', {
                      changesUrl: readonly ? nil : changes_url,
                      asset: asset, facts: facts_with_object_asset(asset.facts), dataAssetDisplay: data_asset_display
                    })
  end

  def data_asset_display_for_plate(facts)
    facts.with_predicate('contains').map(&:object_asset).reduce({}) do |memo, asset|
      location = TokenUtil.unpad_location(asset.first_value_for('location'))
      if (location && (asset.has_sample? || !asset.barcode.nil?))
        if asset.has_sample?
          aliquotType = asset.first_value_for('aliquotType') || unknown_aliquot_type
        else
          aliquotType = empty_well_aliquot_type
        end
        memo[location] = {
          title: "#{asset.short_description}",
          cssClass: aliquotType,
          url: asset_path(asset)
        } unless location.nil?
      end
      memo
    end
  end

  def data_asset_display_for_tube(facts)
    is_facts_values = facts.with_predicate('is').map { |f_is| [f_is.predicate, f_is.object].join('-') }
    aliquot_fact = facts.with_predicate('aliquotType').first
    if aliquot_fact
      css_classes = [(aliquot_fact.object || unknown_aliquot_type), is_facts_values].compact.join(' ')
      url = ((aliquot_fact.class == Fact) ? asset_path(aliquot_fact.asset) : '')
      title = "#{aliquot_fact.asset.short_description}"
    else
      css_classes = is_facts_values
      url = ''
      title = ''
    end
    {
      aliquot: {
        cssClass: css_classes, title: title, url:  url
      }
    }
  end

  def data_asset_display(facts)
    return data_asset_display_for_plate(facts) if facts.with_predicate('contains').count > 0

    data_asset_display_for_tube(facts)
  end

  def svg(name)
    name = 'TubeRack' if name == 'Plate'
    name = 'Tube' if name == 'SampleTube'

    Rails.application.assets["#{name.downcase}"].to_s.html_safe || "('#{name.downcase}.svg' not found)"
  end

  def svg_for_facts(facts)
    svg(facts.select { |f| f.predicate == 'a' }.pluck(:object).first)
  end

  def show_alert(data)
    @alerts = [] unless @alerts
    @alerts.push(data)
  end

  def trigger_alerts
    triggers = @alerts.map do |a|
      "<script type='text/javascript'>$(document).trigger('msg.display_error', #{a.to_json});</script>"
    end.join('\n').html_safe if @alerts
  end
end
