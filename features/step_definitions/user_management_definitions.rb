Given(/^I am an operator called "([^"]*)"$/) do |name|
  FactoryGirl.create :user_with_barcode, {
      :username => name,
      :fullname => name,
      :role => 'operator'
  }
end

Then(/^I am not logged in$/) do
  expect(page.has_content?("Not logged")).to eq(true)
end


When(/^I log in with barcode "(\d+)"$/) do |user_barcode|
  n=find('.logged-out')
  n.click
  fill_in('Scan a user barcode', :with => user_barcode)
  click_on('Login')
end

When(/^I log out$/) do
  n=find('.logged-in .change-login-status-button')
  n.click
  click_on('Logout')
end


When(/^I log in as an unknown user$/) do
  step(%Q{I log in with barcode "99"})
end

When(/^I log in as "([^"]*)"$/) do |name|
  barcode = User.find_by(:username => name).barcode
  step(%Q{I log in with barcode "#{barcode}"})
end

Then(/^I am logged in as "([^"]*)"$/) do |name|
  expect(page).to have_content("Logged as "+name)
  expect(page).to have_css("body.logged-in")
  expect(page).to have_content("Logged as "+name)
end


Given(/^I have the following users:$/) do |table|
  table.hashes.each do |user|
    FactoryGirl.create :user_with_barcode, {
      :username => user["User"],
      :fullname => user["User"],
      :role => user["Role"]
    }
  end
end

Then(/^I should not be able to access the functionality needed for an operator$/) do
  expect(page).not_to have_css('body.operator-role')
end

Then(/^I should not be able to access the functionality needed for an administrator$/) do
  expect(page).not_to have_css('body.administrator-role')
end

Then(/^I should be able to access the functionality needed for an operator$/) do
  expect(page).to have_css('body.operator-role')
end

Then(/^I should be able to access the functionality needed for an administrator$/) do
  expect(page).to have_css('body.administrator-role')
end
