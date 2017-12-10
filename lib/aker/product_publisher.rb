module Aker
  class ProductPublisher
    def self.product_msg(atype)
      {
        name: atype.name,
        availability: atype.available? ? 'available': 'unavailable',
        requested_biomaterial_type: "DNA",
        TAT: 42,
        product_class: "DNA Sequencing"
      }
    end

    def self.products_list_msg
      ActivityType.all.map{|atype| product_msg(atype)}
    end

    def self.msg
      { 
        catalogue: {
          pipeline: "Samples Extraction",
          url: aker_work_orders_url,
          lims_id: "SamplesExtraction",
          products: products_list_msg
        }
      }
    end

    def self.send_products
      RestClient.post Rails.configuration.aker_work_order_catalogue_url, msg.to_json, {content_type: :json, accept: :json}
    end
  end
end