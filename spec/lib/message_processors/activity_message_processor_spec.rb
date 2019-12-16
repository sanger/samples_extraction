require 'rails_helper'
require 'message_processors/activity_message_processor'

RSpec.describe MessageProcessors::ActivityMessageProcessor do
  context 'an instance of ActivityMessageProcessor' do
    let(:activity) { create(:activity)}
    let(:good_message) { { activity: { id: activity.id, stepTypes: false,
        stepsPending: false, stepsRunning: false, stepsFailed: false, stepsFinished: true
        }
      }.as_json
    }
    let(:bad_message) { { asset_group: {} } }
    let(:mocked_redis) { double('redis') }
    let(:channel) { double('channel', redis: mocked_redis )}
    let(:instance) { MessageProcessors::ActivityMessageProcessor.new(channel: channel)}

    context '#interested_in?' do
      it 'returns true if is an activity message' do
        expect(instance.interested_in?(good_message)).to be_truthy
      end
      it 'returns false if is not an activity message' do
        expect(instance.interested_in?(bad_message)).to be_falsy
      end
    end
    context '#process' do
      it 'updates the configuration of elements to generate for each server message' do
        allow(channel.redis).to receive(:hget).and_return(nil)
        allow(channel.redis).to receive(:hset)
        allow(channel).to receive(:params).and_return({activity_id: activity.id})
        instance.process(good_message)
        expect(mocked_redis).to have_received(:hset).with('activities', activity.id,
          good_message['activity'].except('id').to_json)
      end
    end
  end
end
