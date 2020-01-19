module Callbacks
  class DigestCallbacks < Callback
    on_add_property('remote_digest', :update_remote_digest!)

    def self.update_remote_digest!(tuple, updates, step)
      tuple[:asset].update_attributes(remote_digest: tuple[:object])
    end

  end
end
