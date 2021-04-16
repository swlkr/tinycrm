class Mailer < Roda
  plugin :render
  plugin :mailer, content_type: 'text/html'
  plugin :symbol_views
  plugin :render, engine: 'mab', layout: 'email_layout'

  Mail.defaults do
    if ENV["RACK_ENV"] == "production"
      delivery_method :smtp,
        address: 'smtp.mailgun.org',
        user_name: 'postmaster@tinycrm.swlkr.com',
        password: ENV['SMTP_PASSWORD'],
        port: 587
    else
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

    r.mail 'invite', Integer, "from", Integer do |id, id2|
      @user = User[id]
      @inviter = User[id2]
      no_mail! unless @user && @inviter.nil?

      to @user.email
      subject '[tinycrm] Your invite is inside'

      :invite_email
    end
  end
end
