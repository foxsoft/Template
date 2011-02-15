NAME = @app_path.split('/').last.downcase

run "rm README"

run "rm config/database.yml"
file "config/database.yml", <<-END
development:
  adapter: postgresql
  database: #{NAME}-dev
test:
  adapter: postgresql
  database: #{NAME}-test
production:
  adapter: postgresql
  database: #{NAME}
END
run "cp config/database.yml config/database.yml.example"

run "rm Gemfile"
file "Gemfile", <<-END
source 'http://rubygems.org'
gem 'rails', '3.0.4'
gem 'pg', '~> 0.10.0'
gem 'haml', '~> 3.0.0'
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
run 'bundle'

generate("jquery:install --ui")

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

run "wget -O public/stylesheets/reset.css http://meyerweb.com/eric/tools/css/reset/reset.css"

file "app/views/layouts/application.html.erb", <<-END
<!DOCTYPE html>
<html>
  <head>
    <title>#{NAME}</title>
    <%= stylesheet_link_tag "reset" %>
    <%= javascript_include_tag "//ajax.googleapis.com/ajax/libs/jquery/1.5.0/jquery.min.js" %>
    <script type="text/javascript">
    if (typeof jQuery == 'undefined')
    {
        document.write(unescape("%3Cscript src='/javascripts/jquery.min.js' type='text/javascript'%3E%3C/script%3E"));
    }
    </script>
    <%= javascript_include_tag "//ajax.googleapis.com/ajax/libs/jqueryui/1.8.9/jquery-ui.min.js" %>
    <script type="text/javascript">
        !$.ui && 
          document.write(unescape("%3Cscript src='/javascripts/jquery-ui.min.js' type='text/javascript'%3E%3C/script%3E"));</script>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
END

git :init
git :add => ".", :commit => "-m 'initial commit'"