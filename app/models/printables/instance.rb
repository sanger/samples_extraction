module Printables::Instance
  def print(printer_config)

    facts.with_predicate('a').each do |f|
      printer_name = printer_config[f.object].first
      return

      PMB::PrintJob.new(
        printer_name:printer_name,
        label_template_id: LabelTemplate.for_type(f.object).first.external_id,
        labels:{body:[printable_object]}
      ).save
    end
  end
end
