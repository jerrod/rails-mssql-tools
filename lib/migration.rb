module RailsMssqlTools
  class MissingMigrationRoutinesPath < StandardError; end
end

class ActiveRecord::Migration
  ROUTINES_DIR = 'db/migrate/routines'
  
  raise RailsMssqlTools::MissingMigrationRoutinesPath, "Can't find custom migration path #{ROUTINES_DIR}" if !File.exist?( File.join(RAILS_ROOT, ROUTINES_DIR) )
  
  protected
    def self.update_routines(*file_names)
      file_names.each do |file_name|
        File.open(File.join(RAILS_ROOT, ROUTINES_DIR, file_name), 'rb') do |file|
          say_with_time "Running #{file_name}..." do
              sql = file.readlines.join
            begin
              execute sql
            rescue ActiveRecord::StatementInvalid
              STDOUT << 'Rescued Error: ' + $!.to_s
#              expects ALTER stmts, which fails if not exists
#              so, create a dummy and try again.
#              assumes file name matches proc name
#              and that triggers are grouped in dirs by table name.
              file_name_parts = file_name.split('/')
              routine_name = File.basename(file_name)
              routine_name_parts = routine_name.split('.') # expects my_proc.1.sql as file name
              routine_name = routine_name_parts.first.camelize
              case file_name_parts.first.downcase
                when 'methods'
                  execute "CREATE PROCEDURE #{routine_name} AS Select 1"
                when 'views'
                  execute "CREATE VIEW #{routine_name} AS Select 1"
                when 'triggers'
                  execute "CREATE TRIGGER #{routine_name} ON #{file_name_parts[1]} AFTER INSERT AS Select 1"
              end
              execute sql
            end
          end
        end
      end
    end
end