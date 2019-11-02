class HistoryController < ApplicationController
  def index
    @steps = Step.order(id: :desc).paginate(:page => params[:page], :per_page => 10)
  end
end
