class TransformToRoles < ActiveRecord::Migration
  def self.up
    create_table "roles", :force => true do |t|
      t.column "name", :string, :limit => 100
      t.column "permission_tokens", :string
      t.column "created_by_id", :integer
      t.column "updated_by_id", :integer
      t.timestamps
    end
    
    raise "No migrations until you create roles_users migration without primary key!"
    create_table "roles_users", :force => :true do |t|
      t.column "user_id", :integer
      t.column "role_id", :integer
    end
    
    remove_column :users, :admin
    remove_column :users, :designer
  end 
  
  def self.down
    #Re-add the radiant columns
    add_column :users, :admin, :integer, :limit => 1, :default => 0, :null => false
    add_column :users, :designer, :integer, :limit => 1, :default => 0, :null => false
    
    #We can't know that this extension hasn't been used, so we have to try and recover roles
    #This will make Users with the 'admin' role administrators, and Users with 'developer' role developers
    User.find_in_batches.each do |array|
      array.each do |user|
        roles = user.roles if user.respond_to?(:roles) && user.send(:roles).is_a?(Array)
        if roles
             user.update_attribute(:admin, 1) if user.has_role?("admin")
             user.update_attribute(:designer, 1) if user.has_role?("designer")
        end
      end
    end
    drop_table "roles"
    drop_table "user_roles"
  end
    
end
