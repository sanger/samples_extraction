module Activities
  module BackgroundTasks
    class InferenceTask
      attr_accessor :step_type

      def initialize(step_type)
        @step_type = step_type
      end

      def create(params)
        BackgroundSteps::Inference.create(params.merge(step_type: @step_type))
      end
    end

    def background_tasks
      inference_tasks.concat(
        [
          BackgroundSteps::TransferTubesToTubeRackByPosition,
          BackgroundSteps::TransferPlateToPlate,
          BackgroundSteps::TransferSamples,
          BackgroundSteps::AliquotTypeInference,
          BackgroundSteps::StudyNameInference,
          BackgroundSteps::PurposeNameInference,
          BackgroundSteps::UpdateSequencescape
        ]
      )
    end

    def inference_tasks
      step_types.for_reasoning.map{|type| InferenceTask.new(type)}
    end

    def create_background_steps(ordered_tasks, reasoning_params)
      ordered_tasks.reduce([]) do |current_list, actual_task_class|
        actual_step = actual_task_class.create(reasoning_params)
        current_list.last.update_attributes(next_step: actual_step) unless current_list.empty?
        current_list.push(actual_step)
        current_list
      end
    end

    def do_background_tasks(printer_config=nil, user=nil)
      reasoning_params = { 
        :asset_group => asset_group, 
        :activity => self, 
        :printer_config => printer_config, 
        :user => user,
        :in_progress? => true
      }

      connected_tasks = create_background_steps(background_tasks, reasoning_params)

      # We start executing the first one, as they are connected they will execute in order
      connected_tasks.first.execute_actions if connected_tasks.count > 0
    end

  end
end