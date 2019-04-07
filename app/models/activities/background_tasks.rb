module Activities
  module BackgroundTasks
    class BackgroundTask
      attr_accessor :step_type

      def initialize(step_type)
        @step_type = step_type
      end

      def create!(params)
        @step_type.class_for_task_type.send(:create!, params.merge(step_type: @step_type))
      end

    end

    def background_tasks(step)
      [inference_tasks, background_steps, runners ].flatten.compact.reject{|s| s.step_type==step.step_type}.compact
    end
    
    def background_steps
      step_types.for_task_type('background_step').map{|type| BackgroundTask.new(type)}
      #step_types.for_task_type('background_step').map(&:class_for_task_type)
    end       
       
    def runners
      step_types.for_task_type('runner').map{|type| BackgroundTask.new(type)}
    end

    def inference_tasks
      step_types.for_task_type('cwm').map{|type| BackgroundTask.new(type)}
    end

    def create_background_steps(ordered_tasks, reasoning_params)
      ActiveRecord::Base.transaction do 
        ordered_tasks.reduce([]) do |current_list, actual_task_class|
          actual_step = actual_task_class.create!(reasoning_params)
          current_list.last.update_attributes!(next_step: actual_step) unless current_list.empty?
          current_list.push(actual_step)
          current_list
        end
      end
    end

    def create_connected_tasks(step, printer_config=nil, user=nil)
      reasoning_params = { 
        :asset_group => asset_group, 
        :activity => self, 
        :printer_config => printer_config, 
        :user => user,
        :in_progress? => true
      }

      steps = create_background_steps(background_tasks(step), reasoning_params)
      step.update_attributes(next_step: steps.first)
      [step, steps].flatten.compact
    end

  end
end
