class AlterApnApps < ActiveRecord::Migration # :nodoc:
  
  def self.up
    add_column :apn_apps, :name, :string
    add_column :apn_apps, :apn_dev_cert_passphrase, :string
    add_column :apn_apps, :apn_prod_cert_passphrase, :string
  end

  def self.down
    remove_column :apn_apps, :name
    remove_column :apn_apps, :apn_dev_cert_passphrase
    remove_column :apn_apps, :apn_prod_cert_passphrase
  end
  
end