require 'yaml'
class PlatformConfig
  def self.load
    config_file = File.join(Merb.root, "config", "platform.yml")

    if File.exists?(config_file)
      config = YAML.load(File.read(config_file))

      config.keys.each do |key|
        Merb::Config[key.to_sym] = config[key]
      end
    end
  end
end