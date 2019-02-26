ActiveRecord::Base.transaction do
  pmb_template_name = "sqsc_96plate_label_template_code39"
  lt = LabelTemplate.find_by(name: 'se_ean13_96plate')
  lt.update_attributes(template_type: 'DEPRECATED_PLATE')

  external_id = PMB::LabelTemplate.where(name: pmb_template_name).first.id

  LabelTemplate.create(name: pmb_template_name,
    template_type: 'Plate', external_id: external_id)
end
