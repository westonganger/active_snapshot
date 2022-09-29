source "https://rubygems.org"

# Specify your gem's dependencies in active_snapshot.gemspec
gemspec

ENV["DB_GEM"] ||= "sqlite3"

if (RUBY_VERSION.to_f < 2.5 || false) ### set to true if locally testing old Rails version
  #gem 'rails', '~> 5.0.7'
  #gem 'rails', '~> 5.1.7'
  gem 'rails', "~> 5.2.4"
  if ENV['DB_GEM'] == 'sqlite3'
    gem "sqlite3", '~> 1.3.6'
  else
    gem ENV["DB_GEM"]
  end
else
  #gem 'rails', '~> 6.0.3'
  #gem 'rails', '~> 6.1.1'
  gem 'rails', ENV["RAILS_VERSION"]
  gem ENV['DB_GEM']
end
