# frozen_string_literal: true

# Wraps a print job for Print My Barcode
# https://github.com/sanger/print_my_barcode
class PrintMyBarcodeJob
  def initialize(printer_name:, label_template:, labels:)
    @printer_name = printer_name
    @label_template = label_template
    @labels = labels
  end

  def v1?
    pmb_uri.ends_with?('v1')
  end

  def pmb_uri
    Rails.configuration.pmb_uri
  end

  def save
    v1_request if v1?
  end

  private

  def v1_request
    PMB::PrintJob.new(
      printer_name: @printer_name,
      label_template_id: @label_template.external_id,
      labels: {
        body: @labels
      }
    ).save
  end

  def v2_request; end
end
