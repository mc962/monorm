require 'pg'

class MonoRM::DBConnection

  def self.open
    uri = URI.parse(ENV['DATABASE_URL'])
    @conn = PG::Connection.new(
    user: uri.user,
    password: uri.password,
    host: uri.host,
    port: uri.port,
    dbname: uri.path[1..-1]
    )

    @conn
  end

  def self.instance
    MonoRM::DBConnection.open if @conn.nil?

    @conn
  end

  def self.execute(*args )
    sql_statement = args[0]

    args_counter = 1

    should_return_id = false

    interpolated_sql_statement_elements = sql_statement.split(' ').map do |arg|
      should_return_id = true if /\bINSERT\b/.match(arg)
      if /\bINTERPOLATOR_MARK\b/.match(arg)
        interpolated_arg = arg.gsub(/\bINTERPOLATOR_MARK\b/, "$#{args_counter}")
        args_counter += 1
        interpolated_arg
      else
        arg
      end
    end
    interpolated_sql_statement = interpolated_sql_statement_elements.join(' ')

    args[0] = interpolated_sql_statement
    interpolated_args = args.slice(1..-1)
    interpolated_sql_statement << ' RETURNING id' if should_return_id
    puts "#{interpolated_sql_statement}, #{interpolated_args}"
    @returned_id = instance.exec(interpolated_sql_statement, interpolated_args)
  end

  def silent_execute(*args)

    sql_statement = args[0]

    args_counter = 1

    should_return_id = false

    interpolated_sql_statement_elements = sql_statement.split(' ').map do |arg|
      should_return_id = true if /\bINSERT\b/.match(arg)
      if /\bINTERPOLATOR_MARK\b/.match(arg)
        interpolated_arg = arg.gsub(/\bINTERPOLATOR_MARK\b/, "$#{args_counter}")
        args_counter += 1
        interpolated_arg
      else
        arg
      end
    end
    interpolated_sql_statement = interpolated_sql_statement_elements.join(' ')

    args[0] = interpolated_sql_statement
    interpolated_args = args.slice(1..-1)
    interpolated_sql_statement << ' RETURNING id' if should_return_id    
    @returned_id = instance.exec(interpolated_sql_statement, interpolated_args)

  end

  def self.migrate_exec(*args)
    instance.exec(args[0], args[1..-1])
  end

  def self.cols_exec(*args)
    args = args.join("\n")

    instance.exec(args).fields
  end

  def self.last_insert_row_id
    @returned_id
  end

#################DB Level Methods#####################################
  def self.create_database
    uri = URI.parse(ENV['DATABASE_URL'])
    # creates database name based on configuration listed in DATABASE_URL
    db_name = uri.path[1..-1]
    createdb_arg = "CREATE DATABASE #{db_name}"
    # directly open a new db connection with these credentials, minus db_name
    conn = PG::Connection.new(
    user: uri.user,
    password: uri.password,
    host: uri.host,
    port: uri.port
    )
    # create the new database
    conn.exec(createdb_arg)
    # create migrations table
    MonoRM::Migration.create_migrations_table
    puts "Created database #{db_name}"
  end

  def self.drop_database
    uri = URI.parse(ENV['DATABASE_URL'])
    db_name = uri.path[1..-1]

    %x(dropdb #{db_name} --if-exists)
    puts "Dropped database #{db_name}"
  end

end
