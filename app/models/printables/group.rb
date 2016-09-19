module Printables::Group
  def print(printer_config)
    printer_config.each_pair.map do |type, printer|
      [printer, assets.with_fact('a', type), type]
    end.each do |printer_name, assets, type|
      return

      PMB::PrintJob.new(
        printer_name: printer_name,
        label_template_id: LabelTemplate.for_type(type).first.external_id,
        labels:{body: assets.map(&:printable_object)}
      ).save unless assets.blank?
    end
  end
end
