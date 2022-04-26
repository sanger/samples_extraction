class LabelTemplate < ApplicationRecord
  CLASS_TYPE_TEMPLATE_ALIASES = { 'TubeRack' => 'Plate', 'SampleTube' => 'Tube' }.freeze

  validates_presence_of :name, :external_id
  validates_uniqueness_of :name, :external_id

  def self.for_type(class_type, barcodetype = 'ean13')
    type = CLASS_TYPE_TEMPLATE_ALIASES.fetch(class_type, class_type)

    templates = where(template_type: type)

    if templates.blank?
      raise "Could not find any label template for type \'#{type}\'. "\
            'Please contact LIMS support to fix the problem'
    end

    templates.detect { |t| t.name.include?(barcodetype) } || templates.first
  end
end
