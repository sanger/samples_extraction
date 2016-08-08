class User < ActiveRecord::Base
  has_many :steps

  def generate_token
    update_attributes!(:token => MicroToken.generate(128))
    token
  end

  def clean_session
    update_attributes(:token => nil)
  end

  def session_info
    {:username => username, :fullname => fullname, :barcode => barcode, :role => role}
  end

end
