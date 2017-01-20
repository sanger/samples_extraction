class PushDataJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    printer_config = args
    Rails.logger.debug "#{self.class.name}: I'm performing my job with arguments: #{args.inspect}"


    # This should go in a step_type without user interaction
    Asset.with_predicate('transfer').each do |asset|
      asset.add_facts([Fact.new(:predicate => 'is', :object => 'Used')])
      asset.facts.with_predicate('transfer').each do |fact|
        fact.object_asset.add_facts(asset.facts.with_predicate('sanger_sample_id').map do |aliquot_fact|
          [Fact.new(:predicate => 'sanger_sample_id', :object => aliquot_fact.object),
          Fact.new(:predicate => 'sample_id', :object => aliquot_fact.object)]
        end.flatten)
      end
    end

    Asset.with_fact('pushTo', 'Sequencescape').each do |asset|
      asset.update_sequencescape(printer_config)
      asset.facts.select{|f| f.predicate == 'pushTo' && f.object == 'Sequencescape'}.each do |f|
        f.destroy
      end
    end

  end
end
