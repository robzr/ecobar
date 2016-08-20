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

    def update!
      background_update = fork { run_update } 
      Process.detach background_update 
    end

    private

    def download_dmg(source: EcoBar::DMG_URL, dest: nil)
      File.write(dest, open(source).read)
    end

    def kill_ecobar
      binary = '/Applications/ecoBar.app/Contents/MacOS/BitBarDistro'
      pids = `fuser "#{binary}" 2>&1`.split(/:\s+/)
      return unless pids.length > 1
      pids = pids[1].split(/\s+/)
      pids.each do |pid|
        puts "Killing #{pid}"
        Process.kill('SIGKILL', pid.to_i) if pid =~ /^\d+$/
      end
    end

    def run_update(ppid: nil)
      tmp_dmg = '/tmp/ecoBar.dmg'
      app_dir = '/Applications/ecoBar.app'
      mountpoint = '/Volumes/ecoBar Installer'
      Dir.chdir '/tmp'
      if File.exist? mountpoint
        system %Q{hdiutil detach "#{mountpoint}"}
        50.times do 
          break unless File.exist? mountpoint
          sleep 0.1
        end
        if File.exist? mountpoint
          system %Q{hdiutil detach "#{mountpoint}" -force}
        end
      end
      File.unlink(tmp_dmg) if File.exist? tmp_dmg
      kill_ecobar
      download_dmg(dest: tmp_dmg)
      system %Q{/bin/rm -rf #{app_dir}} if File.exist? app_dir
      system %Q{open "#{tmp_dmg}"} if File.exist? tmp_dmg
    end

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
