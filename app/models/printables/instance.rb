module Printables::Instance
<<<<<<< HEAD
  #
  # Print labels for the current Printables::Instance (eg. Asset) using the
  # default printers defined in printer_config
  #
  # @param printer_config [Hash] Typically returned bu the `User` maps a printer
  #                              type, 'Plate' or 'Tube' to a printer name.
  # @param _username [Void] Unused. Formerly the username.
  #
  # @return [Void]
  #
  def print(printer_config, _username)
    body_print = [printable_object].compact
=======
  # @todo Remove user: https://github.com/sanger/samples_extraction/issues/184
  def print(printer_config, user)
    body_print = [printable_object(user)].compact
>>>>>>> e4b24de (Rubocop - autocorrects)
    return if Rails.configuration.printing_disabled || body_print.empty?
    if !printer_config
      raise 'No printer config provided'
    end

    printer_name = printer_config[Printer.printer_type_for(class_type)]
    label_template = LabelTemplate.for_type(class_type, barcode_type)
    PMB::PrintJob.new(
      printer_name: printer_name,
      label_template_id: label_template.external_id,
      labels: { body: body_print }
    ).save
  end
end
