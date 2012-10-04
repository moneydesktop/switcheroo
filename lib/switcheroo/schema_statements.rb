module Switcheroo
  module SchemaStatements
    def switcheroo(table_name, options = {})
      switch_options = {
        :table_name => table_name,
        :clone_table_name => "clone_#{table_name}",
        :columns => columns(table_name),
        :indexes => indexes(table_name),
        :pk_and_sequence => pk_and_sequence_for(table_name),
        :recorder => ActiveRecord::Migration::CommandRecorder.new(self)
      }
      switch_options[:column_mappings] = switch_options[:columns].inject({}) do |hsh,column|
        hsh[column.name] = column.name
        hsh
      end

      yield ActiveRecord::ConnectionAdapters::Table.new(switch_options[:clone_table_name], switch_options[:recorder])

      prepare_clone_table(switch_options)
      clone_data(switch_options)
      switch_tables(switch_options)
      build_new_indexes(switch_options)
      vacuum_table(switch_options)
    end

    private

    def prepare_clone_table(opts)
      ActiveRecord::Migration.say_with_time("Preparing the new table...") do
        drop_table opts[:clone_table_name] if table_exists?(opts[:clone_table_name])

        execute "CREATE TABLE #{opts[:clone_table_name]} " \
                "(LIKE #{opts[:table_name]} " \
                "INCLUDING DEFAULTS INCLUDING CONSTRAINTS)"
      end
    end

    def clone_data(opts)
      ActiveRecord::Migration.say_with_time("Inserting records into the new table...") do
        process_commands(opts)

        columns_list = []
        values_list = []

        opts[:column_mappings].each do |column,value|
          columns_list << column
          values_list << value
        end

        bulk_insert =  "INSERT INTO #{opts[:clone_table_name]} ("
        bulk_insert << columns_list.join(',')
        bulk_insert << ") SELECT "
        bulk_insert << values_list.join(',')
        bulk_insert << " FROM #{opts[:table_name]}"

        execute bulk_insert
      end
    end

    def process_commands(opts)
      opts[:recorder].commands.each do |cmd, cmd_opts|
        send(cmd, *cmd_opts)

        table, arguments = cmd_opts.shift, cmd_opts

        case cmd
        when :add_column
          col_name, col_type, col_opts = *arguments

          if source_column = col_opts[:source]
            opts[:column_mappings][col_name.to_s] = source_column.to_s
          end

        when :remove_column
          arguments.flatten.each do |col|
            opts[:column_mappings].delete col.to_s

            opts[:indexes].delete_if do |idx|
              idx.columns.map(&:to_s).include?(col.to_s)
            end
          end

        when :rename_column
          source_col, dest_col = *arguments

          opts[:column_mappings].delete source_col.to_s
          opts[:column_mappings][dest_col.to_s] = source_col.to_s
        end
      end
    end

    def switch_tables(opts)
      ActiveRecord::Migration.say_with_time("The ol' switcheroo...") do
        ActiveRecord::Migration.suppress_messages do
          execute "ALTER SEQUENCE #{opts[:pk_and_sequence][1]} OWNED BY #{opts[:clone_table_name]}.#{opts[:pk_and_sequence][0]}"
          execute "DROP TABLE IF EXISTS #{opts[:table_name]} CASCADE"
          execute "ALTER TABLE #{opts[:clone_table_name]} RENAME TO #{opts[:table_name]}"
          execute "ALTER TABLE #{opts[:table_name]} ADD CONSTRAINT #{opts[:table_name]}_pkey PRIMARY KEY(#{opts[:pk_and_sequence][0]})"
        end
      end
    end

    def build_new_indexes(opts)
      opts[:indexes].each do |index|
        ActiveRecord::Migration.say_with_time("Building #{index.name}...") do
          add_index opts[:table_name], index.columns, { :name => index.name, :unique => index.unique }
        end
      end
    end

    def vacuum_table(opts)
      ActiveRecord::Migration.say_with_time("Vacumm analyze...") do
        # VACUUM cannot run inside a transaction block
        commit_db_transaction
        execute "VACUUM ANALYZE #{opts[:table_name]}"

        # The migration will attempt to commit a transaction when it is done
        begin_db_transaction
      end

      ActiveRecord::Migration.say("Boom! Your table has been successfully rebuilt.")
    end
  end
end
