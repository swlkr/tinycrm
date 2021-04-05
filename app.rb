# app.rb

class App < Roda
  plugin :public
  plugin :render, engine: "mab"
  plugin :sessions, secret: ENV.fetch("SESSION_SECRET", SecureRandom.hex(32)), key: "id"
  plugin :route_csrf
  plugin :not_found do
    view "404"
  end

  plugin :default_headers,
    "Content-Type"=>"text/html",
    "Strict-Transport-Security"=>"max-age=16070400;",
    "X-Content-Type-Options"=>"nosniff",
    "X-Frame-Options"=>"deny",
    "X-XSS-Protection"=>"1; mode=block"
  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.style_src :self
    csp.script_src :self
    csp.connect_src :self
    csp.img_src :self
    csp.font_src :self
    csp.form_action :self
    csp.base_uri :none
    csp.frame_ancestors :none
    csp.block_all_mixed_content
  end

  DB = Sequel.sqlite ENV.fetch("DATABASE_URL", "db.sqlite3"), loggers: [Logger.new($stdout)]
  Sequel.extension :migration
  Sequel::Migrator.run(DB, "migrations")

  User = DB[:users]
  Company = DB[:companies]
  Stage = DB[:stages]
  Chance = DB[:chances]
  ChanceStage = DB[:chances_stages]

  def get(r, name)
    r.get name do
      view name
    end
  end

  def sql(*args)
    Sequel.lit *args
  end

  route do |r|
    r.public
    check_csrf!
    @current_user = User.first(id: r.session['user_id'])

    r.root do
      view "root"
    end

    r.get "got-mail" do
      view "got-mail"
    end

    r.on "signup" do
      # SIGNUP GET
      r.get do
        view "signup"
      end

      # SIGNUP POST
      r.post do
        email = r.params["email"]

        if email&.empty?
          response.status == 422
          @error = "You left the email field blank"
          view("signup")
        else
          token = SecureRandom.hex(16)
          token_expires_at = Time.now.to_i + 600
          User
            .insert_conflict(target: :email, update: {token: token, token_expires_at: token_expires_at})
            .insert(email: email, token: token, token_expires_at: token_expires_at)
          r.redirect "/got-mail"
        end
      end
    end

    # LOGIN GET
    r.get "login", String do |token|
      user = User.first sql("token = ? and token_expires_at > ?", token, Time.now.to_i)

      if user
        user.update token: nil, token_expires_at: nil
        r.session['user_id'] = user[:id]
        r.redirect "/chances"
      else
        response.status = 404
        r.halt
      end
    end

    r.on "chances" do
      r.get "new" do
        # CHANCES NEW
        view "chances_new"
      end

      r.get do
        # CHANCES GET
        @chances = Chance.all
        view "chances"
      end

      r.post do
        # CHANCES POST
        company = Company.insert_conflict.insert(name: r.params["company"])
        chance = Chance.insert(company_id: company[:id])
      end
    end
  end
end
