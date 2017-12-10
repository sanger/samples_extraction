class Aker::WorkOrdersController < ApplicationController
  protect_from_forgery :except => :create 


  def index
    @work_orders = WorkOrder.all

  end

  def create
    @work_order = WorkOrder.build_from_params(work_order_params)

    head :created
  end


  private

  def work_order_params
    params.require(:work_order).permit!
  end
end