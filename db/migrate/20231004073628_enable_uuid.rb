class EnableUuid < ActiveRecord::Migration[7.0]
  def change
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    end
  end
end
