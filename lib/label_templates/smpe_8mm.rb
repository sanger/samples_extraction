require './lib/label_template_setup'

# LabelTemplateSetup.register_template('SMPE - 92x8mm - Standard','Plate') do |name, type_id|
#   {
#     name: name,
#     label_type_id: type_id, # Plate
#     labels_attributes:[{
#       name: 'label',
#       bitmaps_attributes:[
# rubocop:todo Layout/LineLength
#         {"horizontal_magnification":"05","vertical_magnification":"1","font":"G","space_adjustment":"00","rotational_angles":"00","x_origin":"0030","y_origin":"0035","field_name":"top_line"},
# rubocop:enable Layout/LineLength
# rubocop:todo Layout/LineLength
#         {"horizontal_magnification":"05","vertical_magnification":"1","font":"G","space_adjustment":"00","rotational_angles":"00","x_origin":"0030","y_origin":"0065","field_name":"bottom_line"}
# rubocop:enable Layout/LineLength
#       ],
# rubocop:todo Layout/LineLength
#       barcodes_attributes:[{"barcode_type":"9","one_module_width":"02","height":"0070","x_origin":"0300","y_origin":"0000","field_name":"barcode"}]
# rubocop:enable Layout/LineLength
#     }]
#   }
# end
