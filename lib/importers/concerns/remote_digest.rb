module Importers
  module Concerns
    module RemoteDigest

      def changed_remote?(asset, remote_asset)
        digest_for_remote_asset(remote_asset) != asset.remote_digest
      end

      def update_digest_with_remote(asset, remote_asset)
        FactChanges.new.tap do |updates|
          updates.add(asset, 'remote_digest', digest_for_remote_asset(remote_asset))
        end
        #asset.update_attributes(remote_digest: digest_for_remote_asset(remote_asset))
      end

      def digest_for_remote_asset(remote_asset)
        Digest::MD5::hexdigest(signature_for_remote(remote_asset))
      end

      def signature_for_remote(remote_asset)
        distinct = remote_asset.attributes.to_json

        # It would be useful to have a hashcode in the sequencescape client api to know
        # if this message is different from a previous one without needing to traverse
        # all the object finding the change
        # Having a :to_json method that returns a json would be pretty sensible too

        # FOR A PLATE
        if remote_asset.respond_to?(:wells) && remote_asset.wells
          # wells.to_a because wells relation does not act as an array
          listw = remote_asset.wells.to_a
          if listw
            # aliquots.to_a, same reason
            listal = listw.compact.map(&:aliquots).map(&:to_a)
            if listal
              listsa = listal.flatten.compact.map{|al| al.sample }
              if listsa
                distinct+=listsa.compact.map(&:attributes).to_json
              end
            end
          end
        end

        # FOR A TUBE
        if remote_asset.respond_to?(:aliquots) && remote_asset.aliquots
          # aliquots.to_a, same reason
          listal = remote_asset.aliquots.to_a
          if listal
            listsa = listal.flatten.compact.map{|al| al.sample }
            if listsa
              distinct+=listsa.compact.map(&:attributes).to_json
            end
          end
        end

        distinct
      end
    end

  end
end
