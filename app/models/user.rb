class User < ActiveRecord::Base
  has_many :steps

  belongs_to :tube_printer, :class_name => 'Printer', :foreign_key => 'tube_printer_id'
  belongs_to :plate_printer, :class_name => 'Printer', :foreign_key => 'plate_printer_id'

  before_save :set_default_printers

  def set_default_printers
    update_attributes(
      :tube_printer => Printer.for_tube.for_default.first,
    )  unless tube_printer
    update_attributes(
      :plate_printer => Printer.for_plate.for_default.first,
    )  unless plate_printer
  end

  def tube_printer_name
    tube_printer.name
  end

  def plate_printer_name
    plate_printer.name
  end

  def generate_token
    update_attributes!(:token => MicroToken.generate(128))
    token
  end

  def clean_session
    update_attributes(:token => nil)
  end

  def session_info
    {:username => username, :fullname => fullname, :barcode => barcode, :role => role,
      :tube_printer_name => tube_printer_name, :plate_printer_name => plate_printer_name}
  end

end
