# frozen_string_literal: true

# Namespace for message render
module Messages
  # When an activity is completed we send a record of it to the ML Warehouse
  # This class handles the rendering of this message.
  class Activity
    # The {::Activity} that is being rendered
    attr_reader :activity

    def initialize(activity)
      @activity = activity
    end

    # Hash object used by #to_json to render the message
    def as_json
      {
        sample_extraction_activity: payload,
        lims: 'samples_extraction'
      }
    end

    private

    # Main payload of the message
    def payload
      {
        samples: sample_payload,
        activity_type: activity.activity_type_name,
        instrument: activity.instrument_name,
        kit_barcode: activity.kit_barcode,
        kit_type: activity.kit_type,
        date: activity.completed_at,
        user: activity.last_user_fullname,
        _activity_id_: activity.id
      }
    end

    def sample_payload
      activity.assets.flat_map do |asset|
        input_barcode = asset.walk_transfers.barcode
        asset.supplier_sample_name_facts.map do |fact|
          {
            supplier_sample_name: fact.object,
            input_barcode: input_barcode,
            output_barcode: asset.barcode
          }
        end
      end
    end
  end
end
