module Syncoku
  module CaptureBackup
    include Runnable
    include Git

    def capture
      puts "Capturing #{production_app_name} backup..."
      run_on_production("pg:backups:capture")
      run_on_production("pg:backups:url").strip
    end

    def run_on_production(command)
      run_command "heroku #{command} --app #{production_app_name}"
    end


    def production_app_name
      @production_app_name ||= extract_app_name 'production'
    end

  end
end
