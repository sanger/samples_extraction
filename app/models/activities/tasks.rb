module Activities
  module Tasks

    def do_task(step_type, user, step_params, printer_config, asset_group)
      step = find_or_create_step(step_type, user, step_params, asset_group)
      connected_tasks = create_connected_tasks(step, printer_config, user)

      step.execute_actions
      #step.update_attributes!(state: 'complete')

      #if step && step.created_asset_group
      #  step.created_asset_group.delay.print(printer_config, user.username)
      #end

      #step.update_attributes!(:state => 'complete') unless step.in_progress?

      #step
    end


    def find_or_create_step(step_type, user, step_params, asset_group)
      steps.create!(:step_type => step_type, :asset_group_id => asset_group.id, :user_id => user.id)
    end

    def find_or_create_step2(step_type, user, step_params, asset_group)
      perform_step_actions_for('before_step', self, step_type, step_params)

      step = steps.in_progress.for_step_type(step_type).first
      if (step.nil? && params_for_create_and_complete_the_step?(step_params))
        return steps.create!(:step_type => step_type, :asset_group_id => asset_group.id,
          :user_id => user.id)
      end
      if params_for_progress_with_step?(step_params)
        unless step
          group = AssetGroup.create!
          unless step_params[:data_action]=='linking'
            if step_params[:assets]
              group.assets << step_params[:assets]
            else
              group.assets << asset_group.assets
            end
          end
          step = steps.create!(:step_type => step_type, :asset_group_id => group.id,
            :user_id => user.id, :in_progress? => true, :state => 'in_progress')
        end
        perform_step_actions_for('progress_step', step, step_type, step_params)

        step.progress_with(step_params[:assets], step_params[:state])
      else
        if step && params_for_finish_step?(step_params)
          step.finish
        else
          raise StepWithoutInputs
        end
      end
      return step
    end


    def perform_step_actions_for(id, obj, step_type, step_params)
      if step_params[:data_action_type] == id
        params = step_params[:file] ? {:file => step_params[:file] } : JSON.parse(step_params[:data_params])
        value = obj.send(step_type.step_template, step_type, params)
      end
    end

    def params_for_create_and_complete_the_step?(step_params)
       (step_params.nil? || step_params[:state].nil? || step_params[:state] == 'done')
    end

    def params_for_progress_with_step?(step_params)
      # || (step_params[:data_params]!='{}')))
      (!step_params.nil? &&
        ((step_params[:state]!='done' && step_params[:data_action_type]=='progress_step')))
    end

    def params_for_finish_step?(step_params)
      !params_for_progress_with_step?(step_params)
    end


  end
end
