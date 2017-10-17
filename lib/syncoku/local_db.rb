module Syncoku

  class LocalDb
    include Runnable
    include CaptureBackup

    def sync(args)
      if File.exist?("#{dump_filename}")
        ask_to_download
      else
        download
      end
      drop_and_create
      pg_restore
      migrate
      if args.include?("--skip-after-sync")
        puts "Skipping syncoku:after_sync task"
      else
        run_hook 'after_sync'
      end
      `touch tmp/restart.txt`
    end

    def rebuild(args)
      kill_connections
      puts "Rebuilding database"
      run_command "bundle exec rake db:drop db:create db:migrate"
      puts "Seeding"
      run_command "bundle exec rake db:seed"
    end

    private

    def run_hook(name)
      if test_command "rake syncoku:#{name}"
        puts "#{name} hook run"
      else
        puts "Skipping #{name} hook. Define a Rake task called syncoku:#{name} to activate."
      end
    end

    def ask_to_download
      print "Found existing #{dump_filename}. Choose:\n  D = download new backup, or\n  R = reuse existing backup\nPress D or R or anything else to abort: "
      proceed = STDIN.getch.downcase
      puts proceed
      if proceed == 'd'
        download
      elsif proceed == 'r'
        puts "OK, reusing backup"
      else
        exit 1
      end
    end

    def download
      run_command "curl -o #{dump_filename} \"#{capture}\""
    end

    def kill_connections
      pids = `ps x|grep postgres|grep #{database_config["database"]} | grep -v 'grep' | cut -b 1,2,3,4,5,6`.gsub(/[^0-9]/, ' ').split(' ')
      if pids.any?
        puts "Killing #{pids.size} Postgres connection(s) (#{pids.join(", ")})"
        pids.each do |pid|
          `kill #{pid}`
        end
      else
        puts "No connections to kill"
      end
    end

    def drop_and_create
      kill_connections
      puts "Dropping and recreating #{database_name} database"
      run_command "bundle exec rake db:drop db:create"
    end

    def migrate
      run_command "bundle exec rake db:migrate"
    end

    def pg_restore
      puts "Restoring database from #{dump_filename}"
      options = []
      options << "--verbose"
      options << "--clean"
      options << "--no-acl"
      options << "--no-owner"
      options << "--username=#{database_config["user"]}" if database_config["user"]
      options << "--password=#{database_config["password"]}" if database_config["password"]
      options << "--dbname=#{database_name}"
      options << "--port=#{database_config["port"] || "5432"}"
      output = `pg_restore #{options.join(' ')} #{dump_filename} 2> /dev/null`
      if output =~ /a transfer is currently in progress/
        puts "It looks like a backup is already in progress (or possibly stuck):"
        puts output
        `heroku pg:backups --app #{production_app}`
        puts "Use pg:backups delete to remove the offending backup (or wait a bit to see if it fixes itself)"
        exit 1
      end
    end

    def database_name
      database_config["database"]
    end

    def database_config
      YAML.load(File.read("config/database.yml"))["development"]
    end

    def dump_filename
      ".syncoku.dump"
    end

  end
end
