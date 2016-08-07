Given(/^I am an operator called "([^"]*)"$/) do |name|
  FactoryGirl.create :user_with_barcode, {
      :username => name,
      :fullname => name
  }
end

Then(/^I am not logged in$/) do
  page.should have_content("Not logged")
end


When(/^I log in with barcode "(\d+)"$/) do |user_barcode|
  find('.logged-out .login-button').click
  fill_in('Scan a user barcode', :with => user_barcode)
  click_on('Login')
end

When(/^I log in as an unknown user$/) do
  step(%Q{I log in with barcode "99"})
end

When(/^I log in as "([^"]*)"$/) do |name|
  barcode = User.find_by(:username => name).barcode
  step(%Q{I log in with barcode "#{barcode}"})
end

Then(/^I am logged in as "([^"]*)"$/) do |arg1|
  expect(page.has_content?("Logged as Bob")).to eq(true)
end


