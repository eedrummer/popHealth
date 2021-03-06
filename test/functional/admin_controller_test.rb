require 'test_helper'
include Devise::TestHelpers

class AdminControllerTest < ActionController::TestCase

  setup  do

    dump_database

    collection_fixtures 'users'

    @admin = User.where({email: 'admin@test.com'}).first
    @user = User.where({email: 'noadmin@test.com'}).first
    @user2 = User.where({email: 'noadmin2@test.com'}).first
    @unapproved_user = User.where({email: 'unapproved@test.com'}).first

    @admin2 = User.where({email: 'admin2@test.com'}).first

    @user_ids = [] << @user.id

  end

  test "should get user list if admin" do
    sign_in @admin
    get :users
    users = assigns[:users]
    assert_not_nil users
    assert_response :success
  end

  test "should not get user list if not admin" do
    sign_in @user
    get :users
    users = assigns[:users]
    assert_nil users
    assert_response 403
  end

  test "promote user should make user admin" do
    sign_in @admin
    assert !@user.admin?
    post :promote, username: @user.username, role: 'admin'
    @user = User.find(@user.id)
    assert @user.admin?
    assert_response :success
  end

  test "demote user should make user not admin" do
    sign_in @admin
    assert @admin2.admin?
    post :demote, username: @admin2.username, role: 'admin'
    @admin2 = User.find(@admin2.id)
    assert !@admin2.admin?
    assert_response :success
  end

  test "should not be able to promote if not admin" do
    sign_in @user
    assert !@user.admin?
    post :promote, username: @user.username, role: 'admin'
    @user = User.find(@user.id)
    assert !@user.admin?
    assert_response 403
  end

  test "should not be able to demote if not admin" do
    sign_in @user
    assert @admin2.admin?
    post :demote, username: @admin2.username, role: 'admin'
    @admin2 = User.find(@admin2.id)
    assert @admin2.admin?
    assert_response 403
  end

  test "disable user should mark the user disabled" do
    sign_in @admin
    post :disable, username: @user2.username, disabled: 1
    @user2.reload
    assert @user2.disabled
    assert_response :success
  end

  test "enable user should mark the user enabled" do
    @user2.disabled = true
    @user2.save!
    assert @user2.disabled

    sign_in @admin
    post :disable, username: @user2.username, disabled: 0
    @user2.reload
    assert !@user2.disabled
    assert_response :success
  end

  test "disable user should not disable the user if not admin" do
    sign_in @user
    post :disable, username: @user2.username, disabled: 1
    @user2.reload
    assert !@user2.disabled
    assert_response 403
  end

  test "enable user should not enable the user if not admin" do
    @user2.disabled = true
    @user2.save!
    assert @user2.disabled

    sign_in @user
    post :disable, username: @user2.username, disabled: 0
    @user2.reload
    assert @user2.disabled
    assert_response 403
  end

  test "approve user should approve the user" do
    sign_in @admin
    assert !@unapproved_user.approved?
    post :approve, username: @unapproved_user.username
    @unapproved_user = User.find(@unapproved_user.id)
    assert @unapproved_user.approved?
    assert_response :success
  end

  test "approve user should not approve the user if not admin" do
    sign_in @user
    assert !@unapproved_user.approved?
    post :approve, username: @unapproved_user.username
    @unapproved_user = User.find(@unapproved_user.id)
    assert !@unapproved_user.approved?
    assert_response 403
  end

  test "disable invalid user should not freak out" do
    sign_in @admin
    post :disable, username: "crapusername"
    assert_response :success
  end

  test "promote invalid user should not freak out" do
    sign_in @admin
    post :promote, username: "crapusername", role: 'admin'
    assert_response :success
  end

  test "approve invalid user should not freak out" do
    sign_in @admin
    post :approve, username: "crapusername"
    assert_response :success
  end

end
