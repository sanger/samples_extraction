module Activities::JsonAttributes
  def initial_json_attributes(current_user=nil)
    {
       activity: {
         id: id,
         completed_at: completed_at,
         activity_type_name: activity_type.name,
         instrument_name: instrument.name || instrument.barcode,
         kit_name: kit.barcode,
         selectedAssetGroup: owned_asset_groups.first.id
       },
      tubePrinter: {
        optionsData: Printer.for_tube.map{|a| [a.name, a.id]},
        defaultValue: current_user && current_user.tube_printer ? current_user.tube_printer.id : nil
      },
      platePrinter: {
        optionsData: Printer.for_plate.map{|a| [a.name, a.id]},
        defaultValue: current_user && current_user.plate_printer ? current_user.plate_printer.id : nil
      }
    }.merge(json_attributes)
  end

  def json_attributes
    running_activity = running? || editing?
    {
      activityRunning: running? || editing?,
      messages: ApplicationController.helpers.messages_for_activity(self),
      assetGroups: ApplicationController.helpers.asset_groups_data(self),
      stepTypes: ApplicationController.helpers.step_types_control_data(self),
      dataRackDisplay: ApplicationController.helpers.data_rack_display_for_asset_group(self.asset_group),
      stepsPending: ApplicationController.helpers.steps_data_for_steps(steps.pending),
      stepsRunning: ApplicationController.helpers.steps_data_for_steps(steps.running),
      stepsFailed: ApplicationController.helpers.steps_data_for_steps(steps.failed),
      stepsFinished: ApplicationController.helpers.steps_data_for_steps(self.steps.finished.reverse)
    }
  end  
end