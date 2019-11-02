module Activities
  module Tasks

    def create_step(params)
      step = params[:step_type].class_for_task_type.create!({
                                                 activity: self,
                                                 printer_config: params[:printer_config],
                                                 step_type: params[:step_type],
                                                 asset_group: params[:asset_group],
                                                 user: params[:user]})

      connected_tasks = create_connected_tasks(step, params[:asset_group], params[:printer_config], params[:user])
      step.run!
      step
    end

  end
end
