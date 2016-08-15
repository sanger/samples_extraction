module ApplicationHelper
  def bootstrap_link_to(name = nil, options = nil, html_options = nil, &block)
    modified_options = {:class => 'btn btn-default'}
    modified_options.merge!(html_options) if html_options
    link_to(name, options, modified_options)
  end

  def svg(name)
    #file_path = "#{Rails.root}/app/assets/images/#{name}.svg"
    file_path = Dir.glob("#{Rails.root}/app/assets/images/#{name}.svg", File::FNM_CASEFOLD).first
    if File.exists?(file_path)
      File.read(file_path).html_safe
    else
      '(not found)'
    end
  end

  def svg_for_facts(facts)
    svg(facts.select{|f| f.predicate == 'a'}.pluck(:object).first)
  end

end
