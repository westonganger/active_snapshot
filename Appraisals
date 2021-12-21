["sqlite3", "mysql2", "pg"].each do |db_gem|

  appraise "rails_7.0.#{db_gem}" do
    gem "rails", "~> 7.0.0"
    gem db_gem

    if db_gem != "sqlite3"
      remove_gem "sqlite3"
    end
  end

  appraise "rails_6.1.#{db_gem}" do
    gem "rails", "~> 6.1.1"
    gem db_gem

    if db_gem != "sqlite3"
      remove_gem "sqlite3"
    end
  end

  appraise "rails_6.0.#{db_gem}" do
    gem "rails", "~> 6.0.3"
    gem db_gem

    if db_gem != "sqlite3"
      remove_gem "sqlite3"
    end
  end

  appraise "rails_5.2.#{db_gem}" do
    gem "rails", "~> 5.2.4"
    gem db_gem

    if db_gem != "sqlite3"
      remove_gem "sqlite3"
    end
  end

  appraise "rails_5.1.#{db_gem}" do
    gem "rails", "~> 5.1.7"
    gem db_gem

    if db_gem != "sqlite3"
      remove_gem "sqlite3"
    end
  end

  appraise "rails_5.0.#{db_gem}" do
    gem "rails", "~> 5.0.7"

    if db_gem == 'sqlite3'
      gem "sqlite3", "~> 1.3.13"
    else
      gem db_gem
      remove_gem "sqlite3"
    end
  end

end
