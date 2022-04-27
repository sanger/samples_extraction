class ActivityChannel < ApplicationCable::Channel # rubocop:todo Style/Documentation
  def self.connection_for_redis
    ActionCable.server.pubsub.redis_connection_for_subscriptions
  end

  def connection_for_redis
    self.class.connection_for_redis
  end

  def self.redis
    self.connection_for_redis
  end

  def redis
    connection_for_redis
  end

  def self.subscribed_ids
    value = connection_for_redis.get('SUBSCRIBED_IDS')
    return [] unless value

    JSON.parse(value)
  end

  def receive(data)
    process_asset_group(strong_params_for_asset_group(data)) if data['asset_group']
    process_activity(strong_params_for_activity(data)) if data['activity']
  end

  def process_asset_group(strong_params)
    asset_group = AssetGroup.find(strong_params[:id])
    assets = strong_params[:assets]

    # @todo This probably shouldn't a be a silent failure, and we should instead
    # throw something akin to ActionController::ParameterMissing but I'm not
    # currently sure what we expect here. So maintaining existing behaviour.
    return unless assets

    # @note The array here can contain both asset barcodes, and uuids, or even a mixture of the
    # two.
    asset_uuids, asset_barcodes = assets.partition { |identifier| TokenUtil.is_uuid?(identifier) }

    begin
      uuid_assets = Asset.where(uuid: asset_uuids).to_a
      barcode_assets = Asset.find_or_import_assets_with_barcodes(asset_barcodes)

      # Maintaining existing behaviour: register previously unknown fluidx barcodes
      fluidx_barcodes = asset_barcodes.select { |bc| TokenUtil.is_valid_fluidx_barcode?(bc) }
      missing_barcodes = fluidx_barcodes - barcode_assets.map(&:barcode)
      asset_group.update_with_assets(uuid_assets + barcode_assets)

      if missing_barcodes.present?
        asset_group.activity.send_wss_event(
          { error: { type: 'danger', msg: "Could not find barcodes: #{missing_barcodes.join(', ')}" } }
        )
      end
    rescue Errno::ECONNREFUSED => e
      asset_group.activity.send_wss_event({ error: { type: 'danger', msg: 'Cannot connect with sequencescape' } })
    rescue StandardError => e
      asset_group.activity.send_wss_event({ error: { type: 'danger', msg: e.message } })
    end
  end

  def process_activity(strong_params)
    activity = Activity.find(params[:activity_id])

    obj = ActivityChannel.activity_attributes(params[:activity_id])

    %w[stepTypes stepsPending stepsRunning stepsFailed stepsFinished].reduce(obj) do |memo, key|
      memo[key] = !!strong_params[key] unless strong_params[key].nil?
      memo
    end

    redis.hset('activities', params[:activity_id], obj.to_json)

    activity.touch
  end

  def self.default_activity_attributes
    { stepTypes: true, stepsPending: true, stepsRunning: true, stepsFailed: true, stepsFinished: false }.as_json
  end

  def self.activity_attributes(id)
    JSON.parse(redis.hget('activities', id)) || default_activity_attributes
  rescue StandardError => e
    default_activity_attributes
  end

  def strong_params_for_asset_group(params)
    params = ActionController::Parameters.new(params)
    params.require(:asset_group).permit(:id, assets: [])
  end

  def strong_params_for_activity(params)
    params = ActionController::Parameters.new(params)
    params.require(:activity).permit(:id, :stepTypes, :stepsPending, :stepsRunning, :stepsFailed, :stepsFinished)
  end

  def subscribed_ids
    self.class.subscribed_ids
  end

  def stream_id
    "activity_#{params[:activity_id]}"
  end

  def subscribed
    previous_value = subscribed_ids || []
    connection_for_redis.set('SUBSCRIBED_IDS', previous_value.push(stream_id)) unless previous_value.include?(stream_id)

    stream_from stream_id
  end

  def unsubscribed
    previous_value = subscribed_ids
    connection_for_redis.set('SUBSCRIBED_IDS', previous_value.reject { |v| v == stream_id })

    stop_all_streams
  end
end
