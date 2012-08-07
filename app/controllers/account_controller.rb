#  redmine_mit_auth: provides SSL/Touchstone authentication for redmine
#  Copyright (C) 2012 Josh Bialkowski (jbialk@mit.edu)
# 
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
class AccountController < ApplicationController
  before_filter :invoke_shib_monkey_patches 
  before_filter :invoke_ssl_monkey_patches
  unloadable 
  protected
  def invoke_shib_monkey_patches
    RedmineShibAuth::MonkeyPatches
  end
  def invoke_ssl_monkey_patches
      RedmineSslAuth::MonkeyPatches
    end
end
