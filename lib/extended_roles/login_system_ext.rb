module ExtendedRoles
  module LoginSystemExt
    def self.included(base)
      base.class_eval do
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
                role.to_s!
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
    end
  end
end
