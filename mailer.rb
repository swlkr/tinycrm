class Mailer < Roda
  plugin :render
  plugin :mailer, content_type: 'text/html'
  plugin :symbol_views
  plugin :render, engine: 'mab', layout: 'email_layout'

  if ENV["RACK_ENV"] == "production"
    Mail.defaults do
      delivery_method :smtp,
        address: 'smtp.gmail.com',
        user_name: 'swlkr.rbl@gmail.com',
        password: ENV['GMAIL_APP_PASSWORD'],
        port: 587
    end
  else
    Mail.defaults do
      delivery_method :logger
    end
  end

  route do |r|
    from 'Sean <sean@tinycrm.swlkr.com>'

    r.mail 'login', Integer do |id|
      no_mail! unless @user = User[id]

      to @user.email
      subject '[tinycrm] Your magic link to sign in is inside'

      :login_email
    end
  end
end
