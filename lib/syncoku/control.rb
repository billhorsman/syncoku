module Syncoku

  module Control
    extend Syncoku::Runnable

    def self.run(args)
      matching_remotes = remotes & args
      if matching_remotes.size == 0 && remote_index_uniq?
        if key = (remote_index.keys & args)[0]
          matching_remotes = [remote_index[key]]
          args.delete key
        end
      end
      target = case matching_remotes.compact.size
      when 0
        Syncoku::Local.new
      when 1
        remote = matching_remotes[0]
        args.delete remote
        Syncoku::Remote.new(remote)
      else
        puts "Please choose just one remote out of #{remotes.join(" or ")}"
        exit 1
      end
      commands = %w[both db s3 rebuild] & args
      commands << "both" if commands.size == 0
      if commands.size > 1
        puts "Choose just one command"
        exit 1
      else
        args.delete commands[0]
        target.send(commands[0], args)
      end
    end

    def self.remotes
      @remotes ||= run_command("git remote -v | grep heroku | grep push").split("\n").map {|line|
        line.match(/^(.*)\t/)[1]
      }.reject {|r| r == "production" || r == "heroku" }
    end

    def self.remote_index_uniq?
      remote_index.size == remotes.size
    end

    def self.remote_index
      @remote_index ||= Hash[remotes.map{|r| [r.slice(0, 1), r] }]
    end

  end

end