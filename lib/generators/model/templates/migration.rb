class <%= migration_name.underscore.camelize %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
    <%- attributes.each do |attribute| -%>
      t.column :<%= attribute.name %>, :<%= attribute.type %>
    <%- end -%>
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
