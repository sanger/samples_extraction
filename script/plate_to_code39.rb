lt = LabelTemplate.find_by(name: 'se_ean13_96plate')
lt.update_attributes(template_type: 'DEPRECATED_PLATE')

LabelTemplate.create(name: 'sqsc_96plate_label_template_code39', template_type: 'Plate', external_id: 198)
