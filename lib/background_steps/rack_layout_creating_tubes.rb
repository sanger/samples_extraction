class BackgroundSteps::RackLayoutCreatingTubes < Activities::BackgroundTasks::BackgroundStep
  include Steps::Actions

  def process
    rack_layout_creating_tubes
  end
end
