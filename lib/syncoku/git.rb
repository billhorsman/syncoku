module Syncoku
  module Git

    def extract_app_name(name)
      run_command("git remote -v | grep #{name} | grep push").match(/(\/|:)([^\/:]*)\.git/)[2]
    end
  end
end
