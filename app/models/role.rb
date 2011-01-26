require 'json'

class Role < ActiveRecord::Base
  default_scope :order => 'name'
  acts_as_list
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_many :users, :through => 'user_roles'
  validates_uniqueness_of :name
  
  before_save :tokenize_permissions
  #after_initialize :safe_falsify_all_permissions
  after_find :permission_tokens_to_methods
  
  PERMISSION_TYPES = [:can_edit, :can_delete, :can_create, :can_manage]
  OBJECT_TYPES = [:page, :extension, :theme, :user, :page_part]
  PERMISSION_TYPES.each do |permission|
    OBJECT_TYPES.each do |object_type|
      attr_accessor [permission.to_s, object_type.to_s].join("_").to_sym
    end
  end
  
  #Finds all permisson methods (detected by looking for methods starting with key words)
  #TODO find a more elegant regex to skip over write accessors (can_something ends with equals)
  def find_all_permission_methods
    self.methods.select do |method_name|
      method_name.to_s! unless method_name.is_a?(String)
      (
        method_name =~ /\Acan_edit_\w+/ ||
        method_name =~ /\Acan_delete_/ ||
        method_name =~ /\Acan_create_/
      ) && [true, false].include?(self.send(method_name.gsub("=", "")))
    end
  end
  
  private
  def safe_falsify_all_permissions
    PERMISSION_TYPES.each do |permission|
      OBJECT_TYPES.each do |object_type|
        self.send([permission.to_s, object_type.to_s].join("_") + "=", false)
      end
    end
  end
  
  
  #Finds all permisson methods (detected by looking for methods starting with key words) and turns them into a string
  def tokenize_permissions
    permissions = find_all_permission_methods
    #TODO there is a shortcut to do this, I can't remember it
    permissions_hash = {}
    permissions.each do |permission|
      permission.to_s! unless permission.is_a?(String)
      #FIXME better selection regex for finding permission methods!
      permissions_hash[permission] = self.send(permission.gsub("=", ""))
    end
    self.permission_tokens = permissions_hash.to_json
  end
  
  #Sets up correctly instantiated methods with boolean values by parsing JSON'd hash of permissions stored in the database
  def permission_tokens_to_methods
    JSON.parse(self.permission_tokens).each do |key, value|
      self.send(:attr_accessor, key) unless self.responds_to?(key)
      self.send(key, value)
    end
  end
end
