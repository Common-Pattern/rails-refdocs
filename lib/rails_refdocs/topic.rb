module RailsRefdocs
  class Topic
    Resolution = Struct.new(:version, :origin)

    def name
      raise NotImplementedError
    end

    def title
      name
    end

    def source
      raise NotImplementedError
    end

    def layout
      raise NotImplementedError
    end

    def pinnable?
      true
    end

    def lock_gem
      nil
    end

    def locked(lock)
      lock_gem && lock.gem(lock_gem)
    end

    def locked_part(recorded_version)
      recorded_version
    end

    def latest(pin)
      raise NotImplementedError
    end

    def resolve(pin, lock)
      return Resolution.new(latest(pin), "pin #{pin}") if pin
      locked = locked(lock)
      return Resolution.new(locked.version, locked.source) if locked
      Resolution.new(latest(nil), "latest")
    end

    def fetch(version, stage, work_dir)
      raise NotImplementedError
    end

    private

    def log(message)
      RailsRefdocs.log("#{name} #{message}")
    end
  end
end
