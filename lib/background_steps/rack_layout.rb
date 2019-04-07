class BackgroundSteps::RackLayout < BackgroundSteps::BackgroundStep
  include Steps::Actions
  
  def process
    rack_layout
  end
end
