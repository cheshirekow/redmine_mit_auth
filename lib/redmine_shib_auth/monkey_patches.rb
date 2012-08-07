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
module RedmineShibAuth
  module MonkeyPatches
    module AccountPatch
      def login_with_shib_auth
        if params[:force_shib]
          if try_shib_auth
            redirect_back_or_default :controller => 'my', :action => 'page'
            return
          else
            render_403
            return
          end
        end
        if !User.current.logged? and not params[:skip_shib]
          if try_shib_auth
            redirect_back_or_default :controller => 'my', :action => 'page'
            return
          end
        end
                
        login_without_shib_auth
      end
      
      module InstanceMethods
        def try_shib_auth
          session[:email] = request.env["mail"]
          if session[:email].nil?
            return false
          end
          logger.info "Shibboleth auth plugin, mail env var: " + session[:email]
          if session[:email]
            logger.info "   Login with shibboleth email: " + session[:email]
            user = User.find_by_mail(session[:email])
            if user.nil?
              logger.info "   No user with that email, attempting to create one"
              user              = User.new
              user.mail         = session[:email]
              displayName       = request.env["displayName"]
              if displayName.nil?
                user.lastname   = "-"
                user.firstname  = "-"
              else
                names           = displayName.split(" ");
                if(names.length < 2)
                  logger.info "   name array has less than two elements"
                  user.lastname   = "-"
                  user.firstname  = "-"
                else
                  user.lastname   = names.pop;
                  user.firstname  = names.join(" ");
                end
              end
              
              mailsplit         = user.mail.split("@");
              if(mailsplit[1].casecmp("mit.edu"))
                logger.info "   this is not a @mit.edu address"
                user.login      = user.mail                
              else
                logger.info "   this is an @mit.edu address"
                user.login      = mailsplit.shift                
              end
              user.password     = ActiveSupport::SecureRandom.hex(5)
              user.language     = Setting.default_language

              logger.info "   firstname: " + user.firstname
              logger.info "   lastname:  " + user.lastname
              logger.info "   login:     " + user.login
              logger.info "   email:     " + user.mail
              if user.save
                logger.info "   account created"  
                self.logged_user = user
                return true
              else
                logger.info "   account creation failed"
                return false
              end
            else
              # Valid user
              return false if !user.active?
              user.update_attribute(:last_login_on, Time.now) if user && !user.new_record?
              self.logged_user = user
              return true
            end
          end
          false
        end
      end
      
      def self.included(base)
        base.class_eval do
          alias_method_chain :login, :shib_auth
          include RedmineShibAuth::MonkeyPatches::AccountPatch::InstanceMethods
        end
      end      
    end
    AccountController.send(:include, AccountPatch)
  end
end
