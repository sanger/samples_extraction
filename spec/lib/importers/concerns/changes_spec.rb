require 'rails_helper'
require 'remote_assets_helper'
require 'importers/barcodes_importer'

RSpec.describe 'Importers::Concerns::Changes' do
  include RemoteAssetsHelper

  let(:remote_asset) { build_remote_plate }

  context '#refresh_assets' do
  end

  context '#import_barcodes' do
  end
end
