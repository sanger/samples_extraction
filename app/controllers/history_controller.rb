class HistoryController < ApplicationController
  def index
    @steps = Step.all
  end
end
