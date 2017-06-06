class FindUnindexedForeignKeys
  attr_reader :tables
  def initialize
    @tables = ActiveRecord::Base.connection.tables
  end

  def all_foreign_keys
    @all_foreign_keys ||= tables.flat_map do |table_name|
      ActiveRecord::Base.connection.columns(table_name).map {|c| [table_name, c.name].join('.') }
    end.select { |c| c.ends_with?('_id') }
  end

  def indexed_columns
    @indexed_columns ||= tables.map do |table_name|
      ActiveRecord::Base.connection.indexes(table_name).map do |index|
        index.columns.map {|c| [table_name, c].join('.') }
      end
    end.flatten
  end

  def unindexed_foreign_keys
    @unindexed_foreign_keys ||= all_foreign_keys - indexed_columns
  end

  def list
    puts "There are #{unindexed_foreign_keys.count} unindexed foreign keys.  They are:"
    puts unindexed_foreign_keys
  end

  def write_index_migrations
    unindexed_foreign_keys.each do |table_and_column|
      puts WriteIndexMigration.new(table_and_column).get_migration
    end
    puts "Run these migrations."
  end
end

class WriteIndexMigration
  attr_reader :table, :column
  def initialize(table_and_column)
    @table, @column = table_and_column.split(".")
  end

  def get_migration
    "add_index :#{table}, :#{column}"
  end
end

keys = FindUnindexedForeignKeys.new
keys.write_index_migrations
