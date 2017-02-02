module Printables::Instance
  def print(printer_config)
    body_print = [printable_object].compact
    return if Rails.configuration.printing_disabled || body_print.empty?
    f = facts.with_predicate('a').first
    printer_name = printer_config[Printer.printer_type_for(f.object)]
    label_template = LabelTemplate.for_type(f.object).first
    PMB::PrintJob.new(
      printer_name:printer_name,
      label_template_id: label_template.external_id,
      labels:{body: body_print}
    ).save
  end
end
