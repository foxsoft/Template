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

run "rm Gemfile"
file "Gemfile", <<-END
source 'http://rubygems.org'
gem 'rails', '3.0.4'
gem 'pg', '~> 0.10.0'
gem 'haml', '~> 3.0.25'
gem 'haml-rails'
gem 'compass', '~> 0.10.6'
gem 'html5-boilerplate', '~> 0.3.0'
gem 'barista', '~> 1.0.0'
gem 'seed-fu', '~> 2.0.0'
gem 'devise', '~> 1.1'
gem 'cancan', '~> 1.5.0'
gem 'jquery-rails', '>= 0.2.6'

group :test do
  gem 'shoulda'
  gem 'factory_girl'
  gem 'factory_girl_rails'
  gem 'capybara'
end

END

generate("jquery:install --ui")
generate("barista:install")

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
tmp/**/*
GIT

# RVM

# current_ruby = /=> \e\[32m(.*)\e\[m/.match(%x{rvm list})[1]
current_ruby = "1.8.7"
run "rvm gemset create #{app_name}"
run "rvm #{current_ruby}@#{app_name} gem install bundler"
run "rvm #{current_ruby}@#{app_name} -S bundle install"

file ".rvmrc", <<-END
rvm use #{current_ruby}@#{app_name}
END

run "rvm #{current_ruby}@#{app_name} -S compass init rails . -r html5-boilerplate -u html5-boilerplate --force"

git :init
git :add => "." 
git :commit => '-m "initial commit"'