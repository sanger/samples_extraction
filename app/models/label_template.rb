class LabelTemplate < ApplicationRecord
  CLASS_TYPE_TEMPLATE_ALIASES = {
    'TubeRack' => 'Plate',
    'Tube' => 'SampleTube'
  }.freeze

  validates_presence_of :name, :external_id
  validates_uniqueness_of :name, :external_id

  def self.for_type(class_type, barcodetype = 'ean13')
    type = CLASS_TYPE_TEMPLATE_ALIASES.fetch(class_type, class_type)

    templates = where(template_type: type)

    templates_by_barcodetype = templates.select { |t| t.name.include?(barcodetype) }

    templates_by_barcodetype.presence || templates
  end
end
