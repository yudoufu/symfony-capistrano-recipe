
_cset :symfony_lib_dir, "lib/vendor/symfony"
_cset :plugins_dir, "plugins"
_cset :upload_files, %w(config/databases.yml)

_cset :asset_dir, "web"
_cset :asset_children, %w(images js css)

_cset :default_scm_args, "--ignore-externals" # use for deploy:default task

shared_children.push(plugins_dir)
shared_children.push(symfony_lib_dir)

namespace :deploy do
  desc <<-DESC
  DESC
  task :finalize_update, :except => { :no_release => true } do
    run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)

    release_dirs = shared_children.map { |d| File.join(latest_release, d) }.join(" ")
    run "rm -rf #{release_dirs}"

    shared_children.each { |d| run "ln -s #{shared_path}/#{d} #{latest_release}/#{d}" }

    run "mkdir -p #{latest_release}/cache && chmod 777 #{latest_release}/cache"

    # upload any files in 'uploads' dir to latest_release
    upload_files.each { |file| top.upload(File.join("uploads", file), File.join(latest_release, file)) }
    # symfony cc
    run "cd #{latest_release}; php symfony cc"

    if fetch(:normalize_asset_timestamps, true)
      stamp = Time.now.utc.strftime("%Y%m%d%H%M.%S")
      asset_paths = asset_children.map { |p| File.join(latest_release, asset_dir, p) }.join(" ")
      run "find #{asset_paths} -exec touch -t #{stamp} {} ';'; true", :env => { "TZ" => "UTC" }
    end
  end

  desc <<-DESC
    migrate databese for symfony task.

    set :orm,             "doctrine" #now doctrine only
    set :migrate_env,     "prod"
    set :migrate_app,     "frontend"
    set :migrate_options, ""
    set :migrate_target,  :latest
  DESC
  task :migrate, :roles => :db, :only => { :primary => true } do
    orm = fetch(:orm, "doctrine")
    migrate_env = fetch(:migrate_env, "prod")
    migrate_app = fetch(:migrate_app, "frontend")
    migrate_options = fetch(:migrate_options, "")
    migrate_target = fetch(:migrate_target, :latest)

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then current_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end

    puts "#{migrate_target} => #{directory}"
    run "cd #{directory};php symfony --env=#{migrate_env} #{orm}:migrate #{migrate_app} #{migrate_options}"
  end

  task :update_code, :except => { :no_release => true } do
    on_rollback { run "rm -rf #{release_path}; true" }
    _cset :scm_arguments, default_scm_args
    strategy.deploy!
    finalize_update
  end

  desc "full_upgrade project with symfony."
  task :dist_upgrade do
    transaction do
      dist_upgrade_code
      symlink
    end
    restart
  end

  desc "safe_upgrade project (with plugins unless symfony) ."
  task :upgrade do
    transaction do
      upgrade_code
      symlink
    end
    restart
  end

  desc "install all project codes."
  task :install do
    transaction do
      dist_upgrade_code
      symlink
    end
    start
  end

  task :upgrade_code, :except => { :no_release => true } do
    on_rollback { run "rm -rf #{release_path}; true" }
    strategy.deploy!
    upgrade_plugins
    finalize_update
  end

  task :dist_upgrade_code, :except => { :no_release => true } do
    on_rollback { run "rm -rf #{release_path}; true" }
    strategy.deploy!
    upgrade_symfony
    upgrade_plugins
    finalize_update
  end

  desc "[internal] upgrade shared base syfmony library."
  task :upgrade_symfony, :except => { :no_release => true } do
    run "rm -rf #{shared_path}/#{symfony_lib_dir}"
    run "cp -r #{latest_release}/#{symfony_lib_dir} #{shared_path}/#{symfony_lib_dir}"
    run "chmod g+w #{shared_path}/#{symfony_lib_dir}"
  end

  desc "[internal] upgrade shared plugins."
  desc <<-DESC
  DESC
  task :upgrade_plugins, :except => { :no_release => true } do
    run "rm -rf #{shared_path}/#{plugins_dir}"
    run "cp -r #{latest_release}/#{plugins_dir} #{shared_path}/#{plugins_dir}"
    run "chmod g+w #{shared_path}/#{plugins_dir}"
  end

  desc "upload any files in 'uploads' dir to current_release"
  task :uploads, :except => { :no_release => true } do
    upload_files.each { |file| top.upload(File.join("uploads", file), File.join(current_path, file)) }
    cc
  end

  desc "symfony clear cache."
  task :cc, :except => { :no_release => true } do
    run "cd #{current_path}; php symfony cc"
  end
end
