Capistrano::Configuration.instance(:must_exist).load do
  set(:unicorn_stderr_path) { "#{shared_path}/log/unicorn.err.log" }
  set(:unicorn_stdout_path) { "#{shared_path}/log/unicorn.log" }

  namespace :appserver_unicorn do
    desc "Create wrapper for executing the app"
    task :wrapper do
      sudo "rvm wrapper 1.9.3 #{application} #{current_path}/bin/unicorn"
    end

    desc "Executable to be put in upstart configuration"
    task :path do
      "/usr/local/rvm/bin/#{application}_unicorn"
    end

    desc "Executable arguments to be put in upstart configuration"
    task :args do
      "-E #{rails_env} -c #{shared_path}/system/unicorn.conf"
    end

    desc "Pid file to be put in upstart configuration"
    task :pidfile do
      "#{shared_path}/pids/unicorn.pid"
    end

    #
    # Unicorn signals per: http://unicorn.bogomips.org/SIGNALS.html
    #
    desc "Create unicorn configuration file"
    task :config, :roles => :app do
      template = File.read(File.join(File.dirname(__FILE__), "unicorn.conf.erb"))
      buffer   = ERB.new(template).result(binding)
      put buffer, "#{shared_path}/system/unicorn.conf"
    end

    desc "Port to put into nginx config file for upstream appserver"
    task :port do
      unicorn[:port]
    end
  end
end
