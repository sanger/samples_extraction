module Assets::Import::RemoteDigest

  def changed_remote?(remote_asset)
    Digest::MD5::hexdigest(json_for_remote(remote_asset)) != remote_digest
  end

  def update_digest_with_remote(remote_asset)
    update_attributes(remote_digest: Digest::MD5::hexdigest(json_for_remote(remote_asset)))
  end

  def json_for_remote(remote_asset)
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
