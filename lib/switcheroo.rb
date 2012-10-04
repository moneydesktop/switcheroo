require 'switcheroo/schema_statements'

module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      include ::Switcheroo::SchemaStatements
    end
  end
end
