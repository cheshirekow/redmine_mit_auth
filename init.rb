require 'redmine'

Redmine::Plugin.register :redmine_ssl_auth do
  name 'Redmine SSL auth plugin'
  author 'Jorge Bernal'
  description 'Enable authentication using SSL client certificates'
  version '0.0.1'
end
