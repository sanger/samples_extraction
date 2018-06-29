require 'csv'

class UploadedFile < ApplicationRecord
  belongs_to :asset

  def add_facts(asset_elem, facts)
    asset_elem.add_facts(facts)
    asset_elem.add_operations([facts].flatten, step)    
  end

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
      add_facts(asset, [Fact.new(predicate: 'a', object: file_type(params[:content_type])), Fact.new(predicate: 'contents', object_asset: asset)])
    end
    asset    
  end
end
