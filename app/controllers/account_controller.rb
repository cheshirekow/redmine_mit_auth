class AccountController < ApplicationController
  before_filter :invoke_ssl_monkey_patches
  unloadable 
  protected
  def invoke_ssl_monkey_patches
    RedmineSslAuth::MonkeyPatches
  end
end
