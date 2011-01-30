module ExtendedRoles
  module UserExt
    def self.included(base)
      base.class_eval do
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
    end
  end
end
