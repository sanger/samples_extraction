namespace :db do
  namespace :views do
    desc 'Export the views to a schema file'
    task dump_schema: :environment do
      require './lib/views_schema'

      File.open('./db/views_schema.tmp', 'w') do |schema|
        schema.puts '# This is an automatically generated file by rake:db:views:dump_schema'
        schema.puts "require './lib/views_schema'"
        ViewsSchema.each_view do |name, statement, algorithm, security|
          schema.puts 'ViewsSchema.create_view('
          schema.puts "'#{name}',"
          schema.puts "%Q{#{statement}},"
          schema.puts "algorithm: '#{algorithm}', security: '#{security}'"
          schema.puts ')'
        end
      end
      FileUtils.rm_f('./db/views_schema.old')
      File.rename('./db/views_schema.rb', './db/views_schema.old') if File.exist?('./db/views_schema.rb')
      File.rename('./db/views_schema.tmp', './db/views_schema.rb')
    end

    desc 'Reload the dumped schema'
    task schema_load: :environment do
      require './lib/views_schema'

      ActiveRecord::Tasks::DatabaseTasks.send(
        :each_current_configuration,
        ActiveRecord::Tasks::DatabaseTasks.env
      ) do |config|
        ActiveRecord::Base.establish_connection(config)
        load Rails.root.join('db/views_schema.rb')
      end

      # Ensure we switch back to the main dev database.
      ActiveRecord::Base.establish_connection
    end
  end
end

Rake::Task['db:schema:dump'].enhance { Rake::Task['db:views:dump_schema'].invoke }

Rake::Task['db:schema:load'].enhance { Rake::Task['db:views:schema_load'].invoke }

Rake::Task['db:test:prepare'].enhance { Rake::Task['db:views:schema_load'].invoke }
