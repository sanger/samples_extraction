module ApplicationHelper
  def bootstrap_link_to(name = nil, options = nil, html_options = nil, &block)
    modified_options = {:class => 'btn btn-default'}
    modified_options.merge!(html_options) if html_options
    link_to(name, options, modified_options)
  end

  def data_rack_display(facts)
    return '' unless facts.first.class == Fact
    f = facts.select{|f| f.predicate == 'aliquotType'}.first
    if f
      return {:aliquot => {
        :cssClass => f.object,
        :url => asset_path(f.asset)
        }}.to_json
    end

    facts.select{|f| f.predicate == 'contains'}.map do |fact|
      [fact.object_asset, fact.object_asset.facts]
    end.reduce({}) do |memo, list|
      asset, facts = list[0],list[1]
      f = facts.select{|f| f.predicate == 'location'}.first
      location = f.object
      f2 = facts.select{|f| f.predicate == 'aliquotType'}.first
      aliquotType = f2 ? f2.object : nil
      memo[location] = {:cssClass => aliquotType, :url => asset_path(asset)} unless location.nil?
      memo
    end.to_json
  end

  def svg(name)
    name = 'TubeRack' if name == 'Plate'
    name = 'Tube' if name == 'SampleTube'
    file_path = "#{Rails.root}/app/assets/images/#{name}.svg"
    #file_path = Dir.glob("#{Rails.root}/app/assets/images/#{name}.svg", File::FNM_CASEFOLD).first
    if File.exists?(file_path)
      File.read(file_path).html_safe
    else
      '(not found)'
    end
  end

  def svg_for_facts(facts)
    svg(facts.select{|f| f.predicate == 'a'}.pluck(:object).first)
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
