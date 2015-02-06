module Syncoku

  # Responsible for syncing to a remote app
  class Remote
    include Runnable

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
      @app_name ||= run_command("git remote -v | grep #{remote} | grep push").match(/heroku\.com:(.*)\.git/)[1]
    end

  end
end
