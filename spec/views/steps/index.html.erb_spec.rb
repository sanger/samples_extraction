require 'rails_helper'

RSpec.describe "steps/index", type: :view do
  before(:each) do
    assign(:steps, [
      Step.create!(),
      Step.create!()
    ])
  end

  it "renders a list of steps" do
    render
  end
end
