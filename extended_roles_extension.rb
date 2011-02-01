# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

class ExtendedRolesExtension < Radiant::Extension
  version "1.0"
  description "An extension that provides fine-grained and customizable roles for users"
  url "http://github.com/joshmcarthur/radiant_extended_roles"
  
  # extension_config do |config|
  #   config.gem 'some-awesome-gem
  #   config.after_initialize do
  #     run_something
  #   end
  # end

  # See your config/routes.rb file in this extension to define custom routes
  
  def activate
    
    if respond_to?(:tab)
      tab("Settings") do
        add_item "Roles", "/admin/roles"
      end
    else
      admin.tabs.add "Roles", "/admin/roles"
    end
    
    User.send(:include, ExtendedRoles::UserExt)
    User.send(:has_and_belongs_to_many, 'roles')
    
    LoginSystem.send(:include, ExtendedRoles::LoginSystemExt)
    UserActionObserver.send(:observe, User, Page, Layout, Snippet, Role)
    
    Admin::UsersHelper.module_eval do
      def roles(user)
        user.roles.map { |r| r.name }.join(', ')
      end
    end
  
    
    unless defined? admin.role
      Radiant::AdminUI.send :include, ExtendedRoles::AdminUI 
      admin.role = Radiant::AdminUI.load_default_site_regions
    end
    
    #TODO work out how to do this without overriding the views
    #unless admin.users.edit.form && admin.users.edit.form.include?('role_select')
    #  admin.users.edit.delete :edit_roles
    #  admin.users.edit.add :edit_roles, 'role_select', :after => 'edit_password'
    #end
  end
end
