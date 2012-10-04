# Switcheroo

ActiveRecord migration library to speed up schema changes for large PostgreSQL tables

## Usage

Add this line to your application's Gemfile:

    gem 'switcheroo'

And then in an ActiveRecord::Migration

    class AddColumnsToTransactions < ActiveRecord::Migration
      def up
        switcheroo :transactions do |t|
          t.datetime :deleted_date
          t.rename :user_description, :description
          ...
        end
      end

      def down
        switcheroo :transactions do |t|
          t.remove :deleted_date
          t.rename :description, :user_description
          ...
        end
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
