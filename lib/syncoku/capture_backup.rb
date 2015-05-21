module Syncoku
  module CaptureBackup
    include Runnable

    def capture
      puts "Capturing #{production_app_name} backup..."
      run_on_production("pg:backups capture")
      run_on_production("pg:backups public-url")
    end

    def run_on_production(command)
      run_command "heroku #{command} --app #{production_app_name}"
    end


    def production_app_name
      @production_app_name ||= run_command("git remote -v | grep production | grep push").match(/heroku[^:]*:(.*)\.git/)[1]
    end

  end
end
