module ActivitySupport
  def self.included(base)
    base.instance_eval do
      before(:all) do
        Rails.configuration.redis_enabled = true
      end
      after(:all) do
        Rails.configuration.redis_enabled = false
      end
      before do
        @mocked_redis = MockRedis.new
        ActionController::Base.allow_forgery_protection = true
        allow(ActivityChannel).to receive(:redis).and_return(@mocked_redis)
        Capybara.current_driver = :selenium_chrome_headless
        #Capybara.current_driver = :selenium_chrome
      end
    end
  end

  def user_login(user)
    visit '/'
    find('.logged-out').click
    fill_in('Scan a user barcode', with: user.barcode)
    click_on('Login')
  end

  def start_activity(kit)
    click_on('Use')
    fill_in('Scan a kit barcode', with: kit.barcode)
    click_on('Create activity')
  end

  def scan_asset(asset)
    scan_barcode(asset.barcode)
  end

  def scan_barcode(barcode)
    fill_in('Scan a barcode', with: barcode+"\n")
  end
end
