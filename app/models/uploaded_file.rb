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

  def _process
    ActiveRecord::Base.transaction do
      @csv = CSV.new(data)
      add_facts(asset, Fact.new(predicate: 'a', object: 'CSVFile'))
      headers = nil
      @csv.to_a.each_with_index.map do |line, pos|
        if (pos == 0)
          headers = line
        else
          asset_line = Asset.create!
          add_facts(asset_line, [Fact.new(predicate: 'a', object: 'CSVLine'),
            Fact.new(predicate: 'position', object: pos)])
          headers.zip(line).each do |header, value|
            added = Fact.new(predicate: header, object: value)
            add_facts(asset_line, added)
          end
          add_facts(asset, Fact.new(predicate: 'contains', object_asset: asset_line))
        end
      end
      step.update_attributes(state: 'complete')
    end
  ensure
    step.update_attributes(state: 'error') unless step.state == 'complete'    
  end

  def build_asset
    unless asset
      update_attributes(asset: Asset.create)
      _process
    end
    asset    
  end
end
