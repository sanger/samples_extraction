# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabelTemplate, type: :model do
  context '#for_type' do
    let!(:templates) do
      [
        create(:label_template, name: 'se_ean13_96plate', template_type: 'DEPRECATED_PLATE', external_id: 1),
        create(:label_template, name: 'se_code128_96plate', template_type: 'Plate', external_id: 2),
        create(:label_template, name: 'se_ean13_1dtube', template_type: 'DEPRECATED_TUBE', external_id: 3),
        create(:label_template, name: 'se_code128_1dtube', template_type: 'Tube', external_id: 4),
        create(:label_template, name: 'sqsc_96plate_label_template_code39', template_type: 'Plate', external_id: 5),
        create(:label_template, name: 'se_vertical_code39_1dtube', template_type: 'Tube', external_id: 6)
      ]
    end
    context 'when obtaining a template' do
      it 'returns a valid template for each case' do
        expect(LabelTemplate.for_type('Tube', 'ean13')).to eq([templates[3], templates[5]])
        expect(LabelTemplate.for_type('Tube', 'code128')).to eq([templates[3]])
        expect(LabelTemplate.for_type('Tube', 'code39')).to eq([templates[5]])
        expect(LabelTemplate.for_type('Plate', 'ean13')).to eq([templates[1], templates[4]])
        expect(LabelTemplate.for_type('Plate', 'code128')).to eq([templates[1]])
        expect(LabelTemplate.for_type('Plate', 'code39')).to eq([templates[4]])
      end
    end
    context 'when using the wrong template' do
      it 'raise error' do
        expect { LabelTemplate.for_type('Bubidibu', 'ean13') }.to raise_error
      end
    end
    context 'when using the template of an alias labware type' do
      it 'returns a valid template for each case' do
        expect(LabelTemplate.for_type('SampleTube', 'ean13')).to eq([templates[3], templates[5]])
        expect(LabelTemplate.for_type('SampleTube', 'code128')).to eq([templates[3]])
        expect(LabelTemplate.for_type('SampleTube', 'code39')).to eq([templates[5]])
        expect(LabelTemplate.for_type('TubeRack', 'ean13')).to eq([templates[1], templates[4]])
        expect(LabelTemplate.for_type('TubeRack', 'code128')).to eq([templates[1]])
        expect(LabelTemplate.for_type('TubeRack', 'code39')).to eq([templates[4]])
      end
    end
  end
end
