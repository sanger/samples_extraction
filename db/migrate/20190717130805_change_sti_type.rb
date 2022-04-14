class ChangeStiType < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.transaction do
      Step.where(sti_type: "Steps::BackgroundTasks::BackgroundTask").update_all(sti_type: 'Step')
    end
  end
end
