Given(/^I am an operator called "([^"]*)"$/) do |name|
  unless User.find_by(:fullname => name)
    FactoryGirl.create :user_with_barcode, {
      :username => name,
      :fullname => name
    }
  end
end

When(/^I use the browser to enter in the application$/) do
  visit '/'
end

Then(/^I should see the Instruments page$/) do
  page.should have_content("Instruments")
end

Given(/^I have to process these tubes that are on my table:$/) do |table|
  # table is a Cucumber::MultilineArgument::DataTable
  table.hashes.each do |asset_info|
    facts = asset_info['Facts'].split(',').map do |f|
      l = f.split(':')
      FactoryGirl.create :fact, {:predicate => l[0].strip, :object => l[1].strip}
    end
    asset = FactoryGirl.create :asset, {:barcode => asset_info['Barcode'], :facts => facts}
  end
end


Given(/^I have the following kits in house$/) do |table|
  table.hashes.each do |kit_info|
    kit_type = KitType.find_by_name(kit_info["Kit type"])
    unless kit_type
      activity_type = ActivityType.find_by_name(kit_info["Activity type"])
      kit_type = FactoryGirl.create :kit_type, {
        :name =>kit_info["Kit type"],
        :activity_type => activity_type
      }
    end
    FactoryGirl.create :kit, { :barcode => kit_info["Barcode"], :kit_type => kit_type }
  end
end

When(/^I create an activity with instrument "([^"]*)" and kit "(\d+)"$/) do |instrument_name, kit_barcode|
  visit(instruments_path)
  click_on('Use')
  fill_in 'Kit barcode', with: kit_barcode
  click_on('Create')
end

Given(/^we use these activity types:$/) do |table|
  table.hashes.each do |activity_type|
    FactoryGirl.create :activity_type, {:name => activity_type["Name"]}
  end
end

Given(/^we use these step types:$/) do |table|
  table.hashes.each do |step_type|
    activity_types = step_type["Activity types"].split(',').map do |activity_type_name|
      ActivityType.find_by_name(activity_type_name.strip)
    end
    FactoryGirl.create :step_type, {
      :name => step_type["Name"],
      :activity_types => activity_types
    }
  end
end

Given(/^the laboratory has the following instruments:$/) do |table|
  table.hashes.each do |instrument|
    activity_types = instrument["Activity types"].split(',').map do |activity_type_name|
      ActivityType.find_by_name(activity_type_name.strip)
    end
    FactoryGirl.create :instrument, {
      :barcode => instrument["Barcode"],
      :name => instrument["Name"],
      :activity_types => activity_types
    }
  end
end

Then(/^I should have created an empty activity for "([^"]*)"$/) do |arg1|
  activities = ActivityType.find_by_name(arg1).activities
  expect(activities.count).to eq(1)
  expect(activities.first.asset_group.assets.count).to eq(0)
end

When(/^when I scan these barcodes into the selection basket:$/) do |table|
  table.hashes.each do |barcode_info|
    fill_in('Scan a barcode', :with => barcode_info["Barcode"]+"\n")
    find("form.edit_asset_group button.barcode-send").click
  end
end

Then(/^I should see these barcodes in the selection basket:$/) do |table|
  within('form.edit_asset_group') do
    table.hashes.each do |barcode|
      page.should have_content(barcode["Barcode"])
    end
  end
  # table is a Cucumber::MultilineArgument::DataTable
end
