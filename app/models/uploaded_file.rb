require 'csv'
require 'fact_changes'

class UploadedFile < ApplicationRecord
  belongs_to :asset

  def step
    @step ||= Step.new(step_type: StepType.find_or_create_by(name: 'Refresh'), state: 'running')
  end

  def file_type(content_type)
    return 'XMLFile' if content_type=='text/xml'
    return 'CSVFile' if content_type=='text/csv'
    return 'UnknownFile'
  end

  def build_asset(params)
    unless asset
      update_attributes(asset: Asset.create)
      FactChanges.new.tap do |updates|
        updates.add(asset, 'a', file_type(params[:content_type]))
        updates.add(asset, 'contents', asset)
      end.apply(step)
    end
    asset.touch
    asset    
  end
end
