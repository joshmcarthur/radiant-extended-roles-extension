require File.dirname(__FILE__) + '/../spec_helper'

describe 'User' do
  dataset :users
  
  describe 'roles' do
    it 'should not have static roles' do
      users(:admin).should_not respond_to(:admin)
      users(:admin).should_not respond_to(:designer)
    end
    
    it 'should have an HABTM association with roles' do
      users(:admin).should respond_to(:roles) &&
      users(:admin).roles.should is_a?(Array)
    end
    
    it 'should not allow the user access without the correct role' do
      users(:admin).has_role?('admin').should == false
    end
    
    it 'should allow the user access without the correct role' do
      test_user = users(:admin)
      test_user.roles << Role.find_or_create_by_name('admin')
      test_user.has_role?('admin').should == true
    end

    it 'should not allow the user access without the correct role' do
      test_user = users(:admin)
      test_user.roles << Role.find_by_name('admin')
      test_user.has_permission?(:can_manage_pages).should == false
    end
    
    it 'should allow the user access with the correct role' do
      test_user = users(:admin)
      test_user.roles << Role.find_by_name('admin').update_attribute(:can_manage_pages => true)
      test_user.has_permission?(:can_manage_pages).should == true
    end
    
    it 'should allow an admin user with manage pages permission access'
    it 'should not allow an admin user without manage pages permission access'
    it 'should not allow another user with manage pages permission accesss'
  end
end
