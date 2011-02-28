run "rm README"

run "rm config/database.yml"
file "config/database.yml", <<-END
development:
  adapter: postgresql
  database: #{app_name}-dev
test:
  adapter: postgresql
  database: #{app_name}-test
production:
  adapter: postgresql
  database: #{app_name}
END
run "cp config/database.yml config/database.yml.example"

if cap_install = yes?("Using Capistrano? (yes/no)")
  cap_gem =<<-CAP
  group :development do
    gem 'capistrano'
  end
  CAP
else
  cap_gem = ""
end

run "rm Gemfile"
file "Gemfile", <<-END
source 'http://rubygems.org'
gem 'rails', '3.0.5'
gem 'pg', '~> 0.10.0'
gem 'haml', '~> 3.0.25'
gem 'compass', '~> 0.10.6'
gem 'html5-boilerplate'
gem 'barista', '~> 1.0.0'
gem 'seed-fu', '~> 2.0.0'
gem 'devise', '~> 1.1'
gem 'cancan', '~> 1.5.0'
gem 'jquery-rails', '>= 0.2.6'

#{cap_gem}

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
set :repository,  "set your repository location here"

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

create_file "log/.gitkeep"
create_file "tmp/.gitkeep"

append_file ".gitignore", <<-GIT
config/database.yml
public/stylesheets/*.css
public/javascripts/application.js
tmp/**/*
GIT

# RVM

current_ruby = %x{rvm list}.match(/^=>\s+(.*)\s\[/)[1].strip
run "rvm gemset create #{app_name}"
run "rvm #{current_ruby}@#{app_name} gem install bundler"
run "rvm #{current_ruby}@#{app_name} -S bundle install"

file ".rvmrc", <<-END
rvm use #{current_ruby}@#{app_name}
END

file "app/coffeescripts/application.coffee", <<-JS
$(document).ready ->
  # code goes here
JS

# while html5-boilerplate is using andyh git repo as source, we need to use the full path to the library in the -r command
# forked repo path for bundler :git => "git://github.com/andyh/compass-html5-boilerplate.git"
# run this next bit manually for now
# run "declare -x TEMPLATE_ENGINE=\"erb\";rvm #{current_ruby}@#{app_name} -S compass init rails . -r #{`rvm #{current_ruby}@#{app_name} -S bundle show html5-boilerplate`}/lib/html5-boilerplate -u html5-boilerplate --force"

git :init
git :add => "."

puts <<-NOTES
Now run:
"rake jquery:install --ui"
"rake barista:install"
"rake db:create:all"
"compass init rails . -r html5-boilerplate -u html5-boilerplate --force"

"git commit -m 'initial commit'"

NOTES