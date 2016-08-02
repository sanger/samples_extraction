class RerackingController < ActivitiesController

  before_action :set_instrument



  def set_instrument
    @instrument = Instrument.first
    @kit = Kit.first
  end

  def index
  end

  def create
    @asset_group = AssetGroup.create
    @activity_type = ActivityType.find_by_name('Reracking') || ActivityType.first
    @activity = @activity_type.activities.create(
      :instrument => @instrument,
      :activity_type => @activity_type,
      :asset_group => @asset_group,
      )

    respond_to do |format|
      if @activity.save
        format.html
      else
        format.html { render :new }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def steps_finished
    @in_steps_finished = true
    @steps = @activity.previous_steps

    respond_to do |format|
      format.html {
        render 'steps/_finished', :locals => {
          :steps => @steps,
          :activity => @activity,
        }, :layout => false
      }
    end
  end

end
