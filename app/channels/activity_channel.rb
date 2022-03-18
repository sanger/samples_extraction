class ActivityChannel < ApplicationCable::Channel
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
    process_asset_group(strong_params_for_asset_group(data)) if (data["asset_group"])
    process_activity(strong_params_for_activity(data)) if (data["activity"])
  end

  def process_asset_group(strong_params)
    asset_group = AssetGroup.find(strong_params[:id])
    assets = strong_params[:assets]
    if asset_group && assets
      begin
        received_list = assets.filter_map do |uuid_or_barcode|
          Asset.find_or_import_asset_with_barcode(uuid_or_barcode)
        end

        asset_group.update_with_assets(received_list)

        # asset_group.update_attributes(assets: received_list)
        # asset_group.touch
      rescue Errno::ECONNREFUSED => e
        asset_group.activity.send_wss_event({ error: { type: 'danger', msg: 'Cannot connect with sequencescape' } })
      rescue StandardError => e
        asset_group.activity.send_wss_event({ error: { type: 'danger', msg: e.message } })
      end
    end
  end

  def process_activity(strong_params)
    activity = Activity.find(params[:activity_id])

    obj = ActivityChannel.activity_attributes(params[:activity_id])

    ['stepTypes', 'stepsPending', 'stepsRunning', 'stepsFailed', 'stepsFinished'].reduce(obj) do |memo, key|
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
    begin
      JSON.parse(redis.hget('activities', id)) || default_activity_attributes
    rescue StandardError => e
      default_activity_attributes
    end
  end

  def strong_params_for_asset_group(params)
    params = ActionController::Parameters.new(params)
    params.require(:asset_group).permit(:id, :assets => [])
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
