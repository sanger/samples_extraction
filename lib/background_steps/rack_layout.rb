class BackgroundSteps::RackLayout < Activities::BackgroundTasks::BackgroundStep
  include Steps::Actions

  def process
    rack_layout
  end
end
