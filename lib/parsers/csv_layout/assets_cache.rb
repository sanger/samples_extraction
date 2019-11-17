#
# This module allows to perform a single web request for all the barcodes of the
# files by providing a cache functionality to the CsvParser. This is done by recording
# all the barcode parsers instantiated by a CsvParser and perform a request for all the barcodes
# not resolved when asked by one of the barcodes (in #get_asset_for_barcode)
#
module Parsers::CsvLayout::AssetsCache
  def register_barcode_parser(barcode_parser)
    @barcode_parsers ||= []
    @barcode_parsers.push(barcode_parser)
  end

  def get_asset_for_barcode(barcode)
    @cached_assets_from_barcode_parsers ||= {}
    update_cached_assets_from_barcode_parsers! unless @cached_assets_from_barcode_parsers[barcode]
    return @cached_assets_from_barcode_parsers[barcode]
  end

  def unresolved_barcodes_for_cached_assets
    (@barcode_parsers.reject(&:no_read_barcode?).map(&:barcode) - @cached_assets_from_barcode_parsers.keys)
  end

  def update_cached_assets_from_barcode_parsers!
    assets = Asset.find_or_import_assets_with_barcodes(unresolved_barcodes_for_cached_assets)
    assets.compact.each do |asset|
      @cached_assets_from_barcode_parsers[asset.barcode] = asset
    end
  end
end
