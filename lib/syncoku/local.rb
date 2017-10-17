module Syncoku

  # Responsible for syncing to a local app
  class Local
    include Runnable
    include CaptureBackup

    def both(args)
      db(args)
      s3(args) if S3.config?
    end

    def db(args)
      Syncoku::LocalDb.new.sync(args)
    end

    def s3(args)
      Syncoku::S3.new(:development).sync(args)
    end

    def rebuild(args)
      Syncoku::LocalDb.new.rebuild(args)
    end

  end
end
