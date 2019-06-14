module ChangesSupport::TransactionScope

  class ModelAccessor
    def initialize(klass, updates)
      @klass = klass
      @updates = updates
    end

    def where(opts)
    end

    def find(id)
      results = @klass.find(id)
      if (@updates.assets_to_destroy)
        results=results.where.not(uuid: @updates.assets_to_destroy.map(&:uuid))
      end
      if (@updates.assets_to_create)
        results=results.concat(@updates.assets_to_create)
      end
    end

    def find_by(opts)
    end
  end

  def scope(klass)
    @transaction_scopes||={}
    @transaction_scopes[klass.to_s] ||= ModelAccessor.new(klass, self)
  end

end
