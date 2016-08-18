module EcoBar
  require 'open-uri'

  class AutoUpdate
    def initialize
      if remote_version = get_remote_version
        @remote_version = Gem::Version.new(remote_version)
      end
      @local_version = Gem::Version.new(EcoBar::DMG_VERSION)
    end

    def up_to_date?
      if !@remote_version
        :unknown
      elsif @remote_version > @local_version
        false
      else
        true
      end
    end

    private

    def get_remote_version
      version = nil
      open(UPDATE_CHECK_URL) do |handle|
        handle.each_line do |line|
          if line =~ /\s+DMG_VERSION\s*=/
            version=line.sub(/^\s*DMG_VERSION\s*=\s*['"]([0-9.]+)["'].*$/, '\1')
          end
        end
      end
      version
    rescue Exception
      nil
    end

  end
end
