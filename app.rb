# app.rb

class App < Roda
  plugin :public
  plugin :render, engine: "mab"
  plugin :sessions, secret: ENV.fetch("SESSION_SECRET", SecureRandom.urlsafe_base64(64)), key: "id"
  plugin :route_csrf
  plugin :symbol_views
  plugin :slash_path_empty
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

  route do |r|
    r.public
    check_csrf!
    @current_user = User.first(id: r.session['user_id'])
    @current_team = if @current_user
                      Team[@current_user[:team_id]]
                    else
                      {}
                    end

    r.root do
      view "root"
    end

    r.get "gotmail" do
      :gotmail
    end

    # AUTH
    r.is "signup" do
      # SIGNUP GET
      r.get do
        :signup
      end

      # SIGNUP POST
      r.post do
        email = r.params["email"]

        if email&.include?("@")
          domain = r.params["email"].split("@").last

          token = SecureRandom.hex(16)
          token_expires_at = Time.now.to_i + 600

          user_id = User.insert_conflict(
            target: :email,
            update: {
              token: token,
              token_expires_at: token_expires_at
            }
          ).insert(
            email: email,
            token: token,
            token_expires_at: token_expires_at
          )

          user = User.first(email: email)

          unless user[:team_id]
            team_id = Team.insert(name: "My team")
            user.update(team_id: team_id)
          end

          r.redirect "gotmail"
        else
          response.status == 422
          @error = "That's not an email! Try to include an @ symbol ;)"
          :signup
        end
      end
    end

    # LOGIN GET
    r.get "login", String do |token|
      user = User.first Sequel.lit("token = ? and token_expires_at > ?", token, Time.now.to_i)

      if user
        user.update token: nil, token_expires_at: nil
        r.session["user_id"] = user[:id]
        r.redirect "/deals"
      else
        response.status = 404
        r.halt
      end
    end

    unless @current_user
      response.status = 404
      r.halt
    end

    # DEALS
    r.on "deals" do
      r.is do
        r.get do
          # DEALS GET
          @deals = Deal.where(team_id: @current_user[:team_id])
          :deals
        end
      end

      r.is "new" do
        # DEALS NEW
        r.get do
          @assignees = User.where(team_id: @current_user[:team_id])
          @stages = Stage.where(team_id: @current_user[:team_id])
          :deals_new
        end

        # DEALS POST
        r.post do
          company = Company.insert_conflict.insert(r.params["company"]) if r.params["company"]
          contact = Contact.insert_conflict.insert(r.params["contact"]) if r.params["contact"]

          deal = Deal.insert(
            company_id: company ? company[:id] : nil,
            assigned_to: r.params["assignee"],
            team_id: @current_user[:team_id],
            contact_id: contact ? contact[:id] : nil
          )
        end
      end
    end

    # STAGES
    r.on "stages" do
      r.is do
        r.get do
          # STAGES GET
          @stages = Stage.where(team_id: @current_team[:id])
          :stages
        end
      end

      r.is "new" do
        r.get do
          # STAGES NEW
          @stage = Stage.new
          :stages_new
        end

        r.post do
          @stage = Stage.new(r.params["stage"])
          @stage.team = @current_team

          if @stage.valid?
            @stage.save
            r.redirect "/deals/new"
          else
            :stages_new
          end
        end
      end
    end
  end
end
