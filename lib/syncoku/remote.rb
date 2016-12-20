module Syncoku

  # Responsible for syncing to a remote app
  class Remote
    include Runnable
    include Git

    attr_reader :remote

    def initialize(remote)
      @remote = remote
    end

    def both(args)
      db(args)
      s3(args) if S3.config?
    end

    def db(args)
      Syncoku::RemoteDb.new(app_name).sync
    end

    def s3(args)
      Syncoku::S3.new(remote).sync
    end

    def rebuild(args)
      puts "Rebuild not implemented"
    end

    def app_name
      @app_name ||= extract_app_name remote
    end

  end
end
