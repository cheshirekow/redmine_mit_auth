module RedmineSslAuth
  module MonkeyPatches
    module AccountPatch
      def login_with_ssl_auth
        if params[:force_ssl]
          if try_ssl_auth
            redirect_back_or_default :controller => 'my', :action => 'page'
            return
          else
            render_403
            return
          end
        end
        if !User.current.logged? and not params[:skip_ssl]
          if try_ssl_auth
            redirect_back_or_default :controller => 'my', :action => 'page'
            return
          end
        end
                
        login_without_ssl_auth
      end
      
      module InstanceMethods
        def try_ssl_auth
          #logger.info ">>> Login attempt via SSL"
          #request.env.to_hash.each { |key, value| logger.info "   " + key.to_s + ' = ' + value.to_s } 
          session[:email] = request.env["SSL_CLIENT_S_DN_Email"]
          if session[:email]
            logger.info " Login with certificate email: " + session[:email]
            user = User.find_by_mail(session[:email])
            if user.nil?
              logger.info "   No user with that email, attempting to create one"
              user              = User.new
              user.mail         = session[:email]
              displayName       = request.env["SSL_CLIENT_S_DN_CN"]
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
                return false
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
          alias_method_chain :login, :ssl_auth
          include RedmineSslAuth::MonkeyPatches::AccountPatch::InstanceMethods
        end
      end      
    end
    AccountController.send(:include, AccountPatch)
  end
end
