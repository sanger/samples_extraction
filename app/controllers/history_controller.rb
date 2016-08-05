class HistoryController < ApplicationController
  def index
    @steps = Step.paginate(:page => params[:page], :per_page => 5)
  end
end
