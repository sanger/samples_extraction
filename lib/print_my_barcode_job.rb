# frozen_string_literal: true

# Wraps a print job for Print My Barcode
# https://github.com/sanger/print_my_barcode
class PrintMyBarcodeJob
  #
  # Build a new print job
  #
  # @param printer_name [String] The hostname of the printer to use (eg. d304bc)
  # @param label_template [String] The name of the label template to use as registered in Print my barcode
  # @param labels [Array<Hash>] Array of hashes containing label content
  #
  def initialize(printer_name:, label_template:, labels:)
    @printer_name = printer_name
    @label_template = label_template
    @labels = labels
  end

  #
  # Send the print job to print my barcode to trigger printing
  #
  def save
    v1? ? v1_request : v2_request
  end

  private

  #
  # Temporary method during transition. Determines if we are using the v1 or v2 API
  # based on the uri
  #
  # @return [Bool] Returns true if we are using the v1 api
  #
  def v1?
    pmb_uri.ends_with?('v1')
  end

  def pmb_uri
    Rails.configuration.pmb_uri
  end

  def v1_request
    PMB::PrintJob.new(
      printer_name: @printer_name,
      label_template_id: @label_template.external_id,
      labels: {
        body: @labels
      }
    ).save
  end

  def v2_client
    Faraday.new(url: pmb_uri) { |f| f.request :json }
  end

  def v2_request
    v2_client.post('print_jobs', v2_body)
  end

  def v2_body
    { print_job: { printer_name: @printer_name, label_template_name: @label_template.name, labels: @labels } }
  end
end
