run "rm README"

run "rm config/database.yml"
file "config/database.yml", <<-END
development:
  adapter: postgresql
  database: #{app_name}-dev
  username: deploy
test:
  adapter: postgresql
  database: #{app_name}-test
  username: deploy
production:
  adapter: postgresql
  database: #{app_name}
  username: deploy
END

if cap_install = yes?("Using Capistrano? (yes/no)")
  cap_gem =<<-CAP
  group :development do
    gem 'capistrano'
    gem 'capistrano-ext'
  end
  CAP
else
  cap_gem = ""
end

run "rm Gemfile"
file "Gemfile", <<-END
source 'http://rubygems.org'
gem 'rails', '3.1.3'
gem 'pg', '~> 0.12.2'
gem 'bcrypt-ruby', '~> 3.0.0'
gem 'haml', '~> 3.1.4'
gem 'seed-fu', '~> 2.1.0'
gem 'head_start', '~> 0.1.7'
gem 'simple_form'
gem 'jquery-rails'

# gem 'state_machine',
# gem 'cancan', '~> 1.6.7'
# gem 'kaminari'
# gem 'carrierwave'
# gem 'cloudfiles'
# gem 'rmagick'
# gem 'RedCloth'
# gem 'fancybox-rails'

#{cap_gem}

group :assets do
  gem 'sass-rails',   '~> 3.1.5'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'shoulda'
  gem 'factory_girl'
  gem 'factory_girl_rails'
  gem 'capybara'
end

END

if cap_install
file "Capfile", <<-CAP
load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks
CAP

file "config/deploy.rb", <<-DEPLOY
require "bundler/capistrano"
set :application, "#{app_name}"
set :repository,  "git@github.com:foxsoft/#{app_name}.git"

set :scm, :git

role :web, "your web-server here"                          # Your HTTP server, Apache/etc
role :app, "your app-server here"                          # This may be the same as your `Web` server
role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
role :db,  "your slave db-server here"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#\{try_sudo\} touch #\{File.join(current_path,'tmp','restart.txt')\}"
  end
end
DEPLOY

end

file "lib/tasks/test_seed_data.rake", <<-END
namespace :db do
  namespace :test do
    task :prepare => :environment do
      Rake::Task["db:seed_fu"].invoke
    end
  end
end
END

run "rm public/index.html"
run "rm app/views/layouts/application.html.erb"

create_file "tmp/.gitkeep"

append_file ".gitignore", <<-GIT
tmp/restart.txt
*.tmproj
public/uploads
public/assets
.DS_Store
.sass-cache/
GIT

# RVM

current_ruby = %x{rvm list}.match(/^=>\s+(.*)\s\[/)[1].strip
run "rvm gemset create #{app_name}"
run "rvm #{current_ruby}@#{app_name} gem install bundler"
run "rvm #{current_ruby}@#{app_name} -S bundle install"

file ".rvmrc", <<-END
rvm use #{current_ruby}@#{app_name}
END

git :init

puts <<-NOTES
Now run:
rake db:create:all
bundle exec compass init rails -r head_start -u head_start/boilerplate --force

git add .
git commit -m 'initial commit'

NOTES