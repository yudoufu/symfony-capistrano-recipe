# set your application name
set :application, "your application name"
set :deploy_to, "/path/to/#{application}"

#set your repository settings
# now setting use subversion and sftp push copy mode.
set :scm, :subversion
set :repository, "your repository url"

set :deploy_via, :copy
set :copy_strategy, :export
# if you use not subversion, you must change follow setting
#set :default_scm_args "--ignore-externals"

# set your upload files in 'uploads' dir
set :upload_files, %w(config/databases.yml)

# set shared directorys in project dir
#  and, if you change symfony and plugins dir, set follow 2 comment lines
set :shared_children, %w(log web/uploads)
# set :symfony_lib_dir, "lib/vendor/symfony"
# set :plugins_dir, "plugins"

# setting your web servers list
role :web, *%w[
  example1
  example2
]

# setting your app servers list
role :app, *%w[
  example1
  example2
]

# if you use 'migrate', set server name on running migrate task
#role :db, "input your database here"

set :use_sudo, false

# set Apache start/stop tasks on your environment
namespace :deploy do
  task :start do
#    sudo "/etc/init.d/httpd reload"
  end
  task :stop do
#    sudo "/etc/init.d/httpd reload"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
#    sudo "/etc/init.d/httpd reload"
  end
end
