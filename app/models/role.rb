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
  
  
  def after_find
    return if self.permission_tokens.nil?
    JSON.parse(self.permission_tokens).each do |key, value|
      self.class.send(:attr_accessor, key) unless self.class.respond_to?(key)
      self.send(key + '=', value)
    end
  end
  
  PERMISSION_TYPES = [:can_manage]
  OBJECT_TYPES = [:pages, :layouts, :users, :snippets, :extensions]
  PERMISSION_TYPES.each do |permission|
    OBJECT_TYPES.each do |object_type|
      attr_accessor [permission.to_s, object_type.to_s].join("_").to_sym
    end
  end
  
  #Finds all permisson methods (detected by looking for methods starting with key words)
  #TODO find a more elegant regex to skip over write accessors (can_something ends with equals)
  def find_all_permission_methods
    self.methods.select do |method_name|
      method_name =~ /\Acan_\w+[^=]\Z/
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
      permissions_hash[permission] = self.send(permission)
    end
    self.permission_tokens = permissions_hash.to_json
  end
  
end
