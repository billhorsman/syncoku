module Syncoku

  class S3

    attr_reader :to_env, :from_name, :to_name, :from_bucket, :to_bucket, :from_keys, :to_keys

    def initialize(to_env)
      @to_env = to_env
    end

    def sync(args)
      @missing = []
      @from_name = config_value "production.bucket"
      @to_name = config_value "#{to_env}.bucket"
      access_key_id = config_value "access_key_id"
      secret_access_key = config_value "secret_access_key"
      if @missing.any?
        puts "Missing syncoku.yml values prevented S3 sync"
        @missing.each do |path|
          puts "  s3.#{path}"
        end
        return
      end
      puts "Syncing S3 from #{from_name} to #{to_name}..."
      AWS.config access_key_id: access_key_id, secret_access_key: secret_access_key
      @from_bucket = AWS::S3.new.buckets[from_name]
      @to_bucket = AWS::S3.new.buckets[to_name]
      return unless get_keys
      if !simple_sync & !remove_spare
        puts "S3 is in sync. Nothing to do :)"
      end
    end

    def get_keys
      @from_keys = from_bucket.objects.map(&:key)
      @to_keys = to_bucket.objects.map(&:key)
      true
    rescue AWS::S3::Errors::SignatureDoesNotMatch => e
      puts "Can't sync S3 because #{e.message.sub(/^T/, 't')}"
      false
    end

    def simple_sync
      missing = from_keys - to_keys
      return false if missing.empty?
      puts "On #{from_name} but not on #{to_name}: #{"%7d" % missing.size}"
      puts "Copying to #{to_name}"
      missing.each do |key|
        to_bucket.objects[key].copy_from key, { bucket: from_bucket, acl: :public_read}
        print "."
        STDOUT.flush
      end
      puts " done"
      true
    end

    def remove_spare
      spare = to_keys - from_keys
      return false if spare.empty?
      puts "On #{to_name} but not on #{from_name}:   #{"%7d" % spare.size}"
      puts "Deleting from #{to_name}"
      spare.each do |key|
        to_bucket.objects[key].delete
        print "."
        STDOUT.flush
      end
      puts " done"
      true
    end

    def config_value(path)
      value = config.dup["s3"]
      path.split(".").each do |name|
        value = value[name]
        if value.nil?
          @missing << path
          return nil
        end
      end
      value
    end

    def config
      @config ||= YAML.load(File.read("syncoku.yml"))
    end

    def self.config?
      File.exist?("syncoku.yml")
    end

  end

end
