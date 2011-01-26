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
    User.send(:has_and_belongs_to_many, 'roles')
    User.class_eval do
      def has_role?(role)
        begin
          return self.roles.select { |r| r.name == role.to_s }.length > 0
        rescue NoMethodError => e
         throw NoMethodError.new("Could not find the 'roles' relationship - please run rake radiant:extensions:extended_roles:migrate to add database support for this extension.") 
        end
      end
      
      def has_role_with_permission?(role, permission)
        begin
          return self.roles.select { |r| r.name == role.to_s && r.respond_to?(permission) && r.send(permission) == true }.length > 0
        rescue Exception
          return false
        end
      end
      
      def has_permission?(permission)
        begin
          return self.roles.select { |r| r.respond_to(permission) && r.send(permission) == true }.length > 0
        rescue Exception
          return false
        end
      end
    end
    
    LoginSystem.class_eval do
      
      #When permissions work in the following ways:
      # - combinations can be written using _and_ and _or_, e.g.
      # - admin_and_can_manage_pages will require the user both to have the role admin, and 
      #   also have permissions granted on the admin role to manage pages.
      # - admin_or_can_manage_pages will require the user either to have the role admin, or have
      # permissions granted on ANY ONE of their roles that allows the user to manage pages.
      # - admin will require the user to have the role admin, but will not care about permissions
      # - can_manage_pages will require the user to have the permissions to manage pages, but will not
      #   care about roles.
      def user_has_access_to_action(user, action, instance=new)
        permissions = controller_permissions[action.to_s.intern]
        case
          when allowed_roles = permissions[:when]
            allowed_roles = [allowed_roles].flatten
            allowed_roles.any? do |role|
              case
              when role =~ /_and_/
                criteria = role.split(/_and_/)[0..1]
                criteria.first =~ /\Acan_/ ? user.has_role_with_permission?(criteria[1], criteria[0]) : user.has_role_with_permission?(criteria[0], criteria[1])
              when role =~ /_or_/
                criteria = role.split(/_or_/)[0..1]
                criteria.first =~ /\Acan_/ ? user.has_role?(criteria[1]) || user.has_permission?(criteria[0]) : user.has_role?(criteria[0]) || user.has_permission?(criteria[1])
              else
                role =~ /\Acan_/ ? user.has_permission?(role) : user.has_role?(role)
              end
            end
          when condition_method = permissions[:if]
            instance.send(condition_method)
          else
            true
          end
      end
    end
    
    tab 'Settings' do
       add_item "Roles", "/admin/roles", :after => "Users"
    end
    
    unless defined? admin.role
      Radiant::AdminUI.send :include, ExtendedRoles::AdminUI 
      admin.role = Radiant::AdminUI.load_default_site_regions
    end
    
  end
end
