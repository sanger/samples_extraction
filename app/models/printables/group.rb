module Printables::Group
  def print(printer_config)

    return if Rails.configuration.printing_disabled

    assets.each do |asset|
      f = asset.facts.with_predicate('a').first
      printer_name = printer_config[Printer.printer_type_for(f.object)]
      label_template = LabelTemplate.for_type(f.object).first
      PMB::PrintJob.new(
        printer_name:printer_name,
        label_template_id: label_template.external_id,
        labels:{body: [asset.printable_object]}
      ).save
    end
  end
end
