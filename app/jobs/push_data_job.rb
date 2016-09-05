class PushDataJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    Rails.logger.debug "#{self.class.name}: I'm performing my job with arguments: #{args.inspect}"

    Asset.with_fact('pushTo', 'Sequencescape').each do |asset|
      asset.update_sequencescape
      asset.facts.select{|f| f.predicate == 'pushTo' && f.object == 'Sequencescape'}.each do |f|
        f.destroy
      end
    end
  end
end
