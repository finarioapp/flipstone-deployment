Capistrano::Configuration.instance(:must_exist).load do
  set(:rainbows_stderr_path) { "#{shared_path}/log/rainbows.err.log" }
  set(:rainbows_stdout_path) { "#{shared_path}/log/rainbows.log" }

  namespace :appserver_rainbows do
    desc "Create wrapper for executing the app"
    task :wrapper do
      sudo "rvm wrapper 1.9.3-p448 #{application} #{current_path}/bin/rainbows"
    end

    desc "sets environment variables for ruby Garbage Collection"
    task :set_ruby_gc_params do
      match_gc_params = ruby_gc_settings.keys.join("|")
      env_file = "#{f2_rvm_path}/environments/ruby-#{rvm_ruby_string}"

      sudo "cp #{env_file} #{env_file}.bak && awk '!/#{match_gc_params}/' #{env_file}.bak | sudo tee #{env_file}"
      ruby_gc_settings.each do |key, value|
        sudo %{awk 'BEGIN {print "#{key}=#{value}; export #{key}" >> "#{env_file}"}'}
      end
    end

    desc "Executable to be put in upstart configuration"
    task :path do
      "/usr/local/rvm/bin/#{application}_rainbows"
    end

    desc "Executable arguments to be put in upstart configuration"
    task :args do
      "-E #{rails_env} -c #{shared_path}/system/rainbows.conf"
    end

    desc "Pid file to be put in upstart configuration"
    task :pidfile do
      #intentionally left to facilitate switchover
      "#{shared_path}/pids/unicorn.pid"
    end

    #
    # Unicorn signals per: http://unicorn.bogomips.org/SIGNALS.html
    #
    desc "Create rainbows configuration file"
    task :config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "rainbows.conf.erb"))
      buffer   = ERB.new(template).result(binding)
      put buffer, "#{shared_path}/system/rainbows.conf"
    end

    desc "Port to put into nginx config file for upstream appserver"
    task :port do
      rainbows[:port]
    end
  end
end


