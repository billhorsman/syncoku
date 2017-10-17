module Syncoku

  class RemoteDb
    include Runnable
    include CaptureBackup

    attr_reader :app_name

    def initialize(app_name)
      @app_name = app_name
    end

    def sync(args)
      puts "Switch on maintenance mode"
      run_remotely "maintenance:on"
      puts "Restoring database"
      run_remotely "pg:reset DATABASE_URL --confirm #{app_name}"
      run_remotely "pg:backups:restore '#{capture}' DATABASE_URL --confirm #{app_name}"
      run_remotely "run rake db:migrate"
      if args.include?("--skip-after-sync")
        puts "Skipping syncoku:after_sync task"
      else
        run_remotely "run rake syncoku:after_sync"
      end
      run_remotely "restart"
      puts "Switch off maintenance mode"
      run_remotely "maintenance:off"
    end

    def run_remotely(command)
      run_command "heroku #{command} --app #{app_name}"
    end

  end
end
