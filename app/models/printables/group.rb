module Printables::Group
  def classify_for_printing(assets, printer_config)
    assets.reduce({}) do |memo, asset|
      class_type = asset.class_type
      printer_name = printer_config[Printer.printer_type_for(class_type)]
      label_template = LabelTemplate.for_type(class_type).first
      [asset, label_template, printer_name]
      memo[printer_name] = {} unless memo[printer_name]
      memo[printer_name][label_template] = [] unless memo[printer_name][label_template]
      memo[printer_name][label_template].push(asset)
      memo
    end
  end

  def print(printer_config)
    body_print = assets.map(&:printable_object).compact
    return if Rails.configuration.printing_disabled || body_print.empty?
    classify_for_printing(assets, printer_config).each do |printer_name, info_for_template|
      info_for_template.each do |label_template, assets|
        PMB::PrintJob.new(
        printer_name:printer_name,
        label_template_id: label_template.external_id,
        labels:{body: body_print}
      ).save
      end
    end
  end
end
