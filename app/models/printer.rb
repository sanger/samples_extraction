class Printer < ActiveRecord::Base
  scope :for_tube, ->() { where(:printer_type => 'Tube')}
  scope :for_plate, ->() { where(:printer_type => 'Plate')}
  scope :for_default, ->() { where(:default_printer => true)}
end
