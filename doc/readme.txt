Redmine SSL auth plugin
========================

This redmine plugin enables authentication using MIT SSL client certificates or
Touchstone (MIT's shibboleth single sign on service). 

![screenshot](screenshot.png "Redmine with Links")



Usage
--------------------------

It's very simple

*   Install the plugin: ruby script/plugin install 
    git://git.cheshirekow.com/redmine_mit_auth.git
*   Configure apache for SSL authentication (see Configuration)
*   Visit https://YOURSITE/login and click on "use MIT Certificates"
    or "Use Touchstone"



Notes 
--------------------------

*   SSL authentication is based on the plugin by 
    Jorge Bernal <jbernal@ebox-platform.com>
    *   git://github.com/koke/redmine_ssl_auth.git
*   The SSL authentcation  uses the following certificate fields 
    *   CLIENT_S_DN_Email (email, username)
    *   CLIENT_S_DN_CN (display name)
*   It is expected that CLIENT_S_DN_Email is an @mit.edu address. The username
    that is generated is the same as teh athena account. 
*   You can visit /login?skip_ssl=1 to skip SSL authentication and do regular 
    login
*   The Shibboleth authentication expects the apache environment variable 
    "email" to be the email stored for the user in the redmine database
*   If the user does not exist, it will be created
*   You can visit /login?skip_shib=1 to skip shibboleth authentication and do 
    regular login



Configure Apache
--------------------------

Nice tutorial: http://www.vanemery.com/Linux/Apache/apache-SSL.html

In my case, I put the following in my http (port :80) configuration

        <Location /redmine/login/ssl>
            RewriteEngine On
            RewriteCond %{HTTPS} off
            RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
        </Location>
        
To redirect to the secure virtual host. Then in the https (port :443) 
configuration I have

        <Directory /var/www/>
            # allows us to symlink content into the document root
            # the lack of "Indexes" means we don't list files if index.* is missing
            Options FollowSymLinks MultiViews
        
            # disallows .htaccess files
            AllowOverride Limit
        
            # everyone is allowed to view this
            Order allow,deny
            allow from all
        
            # Does not allow unencrypted connections on port 443    
            SSLRequireSSL
        </Directory>
        
        #   SSL Engine Switch:
        #   Enable/Disable SSL for this virtual host.
        SSLEngine on
    
        #   The location of our certificate and private key. The key is used to 
        #   generate a certificate reques, and the certificate is given to us by
        #   MIT 
        SSLCertificateFile    /etc/ssl/certs/ares.pem
        SSLCertificateKeyFile /etc/ssl/private/ares.key
        
        #   If you would like to only allow MIT certificates this may 
        #   be how you explicitly set the authority
        # SSLCACertificateFile    /etc/ssl/mitca.crt
    
        #   Passes SSL_ environment variables to scripts
        <FilesMatch "\.(cgi|shtml|phtml|php)$">
            SSLOptions +StdEnvVars
        </FilesMatch>
    
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>
            
        <Location /redmine/login/ssl>
            SSLVerifyClient require
            SSLRequireSSL
            SSLOptions +StdEnvVars
        </Location>
        
        <Location /redmine/login/shib>
            AuthType shibboleth
            ShibRequestSetting requireSession 1
            Require valid-user
        </Location>
                
                
Questions
--------------------------

To jbialk@mit.edu

