require "roda"
require "haikunator"

require "./model"
require "./mailer"

class App < Roda
  # PLUGINS
  plugin :flash
  plugin :render, engine: "mab"
  plugin :sessions, secret: ENV.fetch("SESSION_SECRET"), cookie_options: { max_age: 86400 * 30 }
  plugin :route_csrf
  plugin :symbol_views
  plugin :slash_path_empty

  plugin :assets,
    css: ["charts.min.css", "app.css"],
    js: ["turbo.min.js"],
    gzip: true

  compile_assets unless ENV["RACK_ENV"] == "development"

  plugin :not_found do
    view "404"
  end

  plugin :default_headers,
    "Content-Type"              => "text/html",
    "Strict-Transport-Security" => "max-age=16070400;",
    "X-Content-Type-Options"    => "nosniff",
    "X-Frame-Options"           => "deny",
    "X-XSS-Protection"          => "1; mode=block"

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

  def login(r, token)
    team = Team.find(identifier: r.params["team"])
    user = User.where(Sequel.lit("team_id = ? and token = ? and token_expires_at > ?", team&.id, token, Time.now.to_i)).first

    if team && user
      # create these on first login only
      %w[follow-up qualified demo negotiation won lost unqualified].each do |name|
        stage = Stage.find(team_id: team.id, name: name)
        if stage.nil?
          Stage.create(team_id: team.id, name: name, color: "#{rand(0..190)},#{rand(0..190)},#{rand(0..190)}")
        end
      end unless user.last_login_at

      user.update token: nil, token_expires_at: nil, last_login_at: Time.now.to_i, demo: 0

      r.session["user_id"] = user[:id]
      r.redirect "/deals"
    else
      response.status = 404
      r.halt
    end
  end

  route do |r|
    r.public
    r.assets
    check_csrf!

    # DEMO USERS
    @current_user = User.first(id: r.session['user_id'])

    unless @current_user
      @current_user = User.find_or_create(email: "#{SecureRandom.hex(7)}@example.com", demo: 1)
      haiku = ::Haikunator.haikunate
      team = Team.create(name: haiku, identifier: haiku)
      @current_user.update(team_id: team.id)

      stages = %w[follow-up qualified demo negotiation won lost unqualified].map do |name|
        {team_id: @current_user.team.id, name: name, color: "#{rand(0..190)},#{rand(0..190)},#{rand(0..190)}"}
      end

      Stage.multi_insert(stages)

      session['user_id'] = @current_user.id
    end

    @current_team = @current_user&.team

    # HOME
    r.root do
      @deals = @current_team.deals
      @companies = @current_team.companies
      @stages = @current_team.stages
      @contacts = @current_team.contacts

      :dashboard
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
        team_identifier = r.params["team"]

        if email&.include?("@")
          token = SecureRandom.hex(16)
          token_expires_at = Time.now.to_i + 600

          # the user may already exist so don't just give away that email
          # to the current demo user
          team = Team.find(identifier: team_identifier)
          user = User.find(team_id: team.id, email: email)

          # this could be bad
          # if the user does not exist
          # only then give away the email
          # to the current user
          if user.nil?
            user = @current_user
            user.email = email
          end
          user.token = token
          user.token_expires_at = token_expires_at
          user.save

          # send email
          Mailer.sendmail("/login/#{user.id}")

          r.redirect "gotmail"
        else
          response.status = 422
          @error = "That's not an email! Try to include an @ in there"
          :signup
        end
      end
    end

    # LOGIN
    r.on "login" do
      r.is do
        # GET /login
        r.get do
          :login
        end

        # POST /login
        r.post do
          login r, r.params["token"]
        end
      end

      # GET /login/:token
      r.on String do |token|
        r.is do
          login r, token
        end
      end
    end

    unless @current_user
      response.status = 404
      r.halt
    end

    # LOGOUT
    r.post "logout" do
      r.session.delete("user_id")
      r.redirect "/"
    end

    # DEALS
    r.on "deals" do
      r.is do
        # DEALS /
        @deals = @current_team.deals
        :deals
      end

      r.on String do |id|
        @companies = @current_team.companies
        @users = @current_team.users
        @stages = @current_team.stages
        @contacts = @current_team.contacts

        if id == "new"
          # DEALS NEW
          # GET /deals/new
          r.get do
            :deals_new
          end

          # DEALS CREATE
          # POST /deals
          r.post do
            company = @current_team.companies.with_hashid(r.params["company_id"]) if r.params["company_id"]
            contact = @current_team.contacts.with_hashid(r.params["contact_id"]) if r.params["contact_id"]
            user = @current_team.users.with_hashid(r.params["user_id"]) if r.params["user_id"]
            stage = @current_team.stages.with_hashid(r.params["stage_id"]) if r.params["stage_id"]

            @deal = Deal.new(r.params.slice("notes", "value"))
            @deal.team = @current_team
            @deal.company = company
            @deal.user = user
            @deal.contact = contact
            @deal.stage = stage

            if @deal.valid?
              @deal.save
              r.redirect "/deals"
            else
              :deals_new
            end
          end
        else
          @deal = @current_team.deals.with_hashid(id)
        end

        r.is "edit" do
          # GET /deals/:id/edit
          # DEALS EDIT
          r.get do
            :deals_edit
          end

          # POST /deals/:id/edit
          # DEALS UPDATE
          r.post do
            company = @current_team.companies.with_hashid(r.params["company_id"]) if r.params["company_id"]
            contact = @current_team.contacts.with_hashid(r.params["contact_id"]) if r.params["contact_id"]
            user = @current_team.users.with_hashid(r.params["user_id"]) if r.params["user_id"]
            stage = @current_team.stages.with_hashid(r.params["stage_id"]) if r.params["stage_id"]

            params = r.params.slice("value", "notes")
            @deal.set params
            @deal.company = company
            @deal.contact = contact
            @deal.user = user
            @deal.stage = stage

            if r.params["status"] == "closed"
              @deal.closed_at = Time.now.to_i
            else
              @deal.closed_at = nil
            end

            if @deal.valid?
              @deal.save
              r.redirect "/deals"
            else
              :deals_edit
            end
          end
        end

        # DEALS DELETE
        r.is "delete" do
          @deal.destroy
          flash['success'] = 'Deal deleted succesfully'
          r.redirect "/deals"
        end
      end
    end

    # STAGES
    r.on "stages" do
      @stages = @current_team.stages

      r.is do
        :stages
      end

      r.is "new" do
        r.get do
          # STAGES NEW
          # GET /stages/new
          @stage = Stage.new
          :stages_new
        end

        r.post do
          # STAGES CREATE
          # POST /stages/new
          params = r.params["stage"].slice("name")
          @stage = Stage.new(params)
          @stage.team = @current_team
          @stage.color = "#{rand(0..190)},#{rand(0..190)},#{rand(0..190)}"

          if @stage.valid?
            @stage.save
            r.redirect "/deals/new"
          else
            :stages_new
          end
        end
      end

      r.is String, "edit" do |id|
        @stage = @stages.with_hashid(id)

        puts @stage

        # STAGES EDIT
        # GET /stages/:id/edit
        r.get do
          :stages_edit
        end

        # STAGES UPDATE
        # POST /stages/:id/edit
        r.post do
          @stage.set r.params.slice("name")

          if @stage.valid?
            @stage.save
            r.redirect "/stages"
          else
            :stages_edit
          end
        end
      end
    end

    # TEAMS
    r.on "teams" do
      r.is "edit" do
        r.get do
          :teams_edit
        end

        r.post do
          @current_team.set(r.params["team"].slice("name", "identifier"))

          if @current_team.valid?
            @current_team.save
            r.redirect "/users"
          else
            response.status = 422
            :teams_edit
          end
        end
      end
    end

    # TEAM MEMBERS
    # USERS
    r.on "users" do
      def params(r)
        r.params["user"].slice("email", "name")
      end

      r.is do
        @users = @current_team.users
        :users
      end

      r.is "new" do
        # GET /users/new
        r.get do
          @user = User.new
          :users_new
        end

        r.post do
          # INVITE
          # USERS NEW POST
          email = r.params.dig("user", "email")
          @user = User.find(team: @current_team, email: email) || User.new(params(r))
          @user.team = @current_team
          @user.token = SecureRandom.hex(16)
          @user.token_expires_at = Time.now.to_i + 600

          if @user.valid?
            @user.save
            Mailer.sendmail("/invite/#{@user.id}/from/#{@current_user.id}") unless @current_user.demo == 1

            flash["no_mail"] = "Email doesn't get sent for demo accounts to prevent abuse. You'll have to sign up and then re-send the login email manually." if @current_user.demo == 1
            r.redirect '/users'
          else
            :users_new
          end
        end
      end

      r.on String do |id|
        r.is "edit" do
          @user = @current_team.users.with_hashid(id)

          r.get do
            :users_edit
          end

          r.post do
            if @current_user.demo == 1
              @user.name = r.params.dig("user", "name")
            else
              @user.set params(r)
            end

            if @user.valid?
              @user.save
              r.redirect "/users"
            else
              :users_edit
            end
          end
        end
      end
    end

    # COMPANIES
    r.on "companies" do
      # GET /companies
      r.is do
        @companies = @current_team.companies
        :companies
      end

      r.on String do |id|
        def params(r)
          r.params["company"].slice("name", "linked_in", "url", "notes")
        end

        if id == "new"
          r.get do
            @company = Company.new
            :companies_new
          end

          r.post do
            @company = Company.new params(r)
            @company.team = @current_team

            if @company.valid?
              @company.save
              r.redirect "/companies"
            else
              :companies_new
            end
          end
        end

        @company = @current_team.companies.with_hashid(id)

        # GET /companies/:hashid
        # COMPANIES SHOW
        r.is do
          :company
        end

        r.is "edit" do
          # GET /companies/:hashid/edit
          r.get do
            :companies_edit
          end

          # POST /companies/:hashid/edit
          r.post do
            @company.set params(r)

            if @company.valid?
              @company.save
              r.redirect "/companies"
            else
              :companies_edit
            end
          end
        end
      end
    end

    # CONTACTS
    r.on "contacts" do
      def params(r)
        r.params["contact"].slice("name", "email", "address", "phone", "linkedin", "notes")
      end

      # GET /contacts
      r.is do
        @contacts = @current_team.contacts
        :contacts
      end

      r.on "new" do
        @companies = @current_team.companies

        # CONTACTS NEW
        # GET /contacts/new
        r.get do
          @contact = Contact.new
          :contacts_new
        end

        # CONTACTS CREATE
        # POST /contacts/new
        r.post do
          @contact = Contact.new params(r)
          @contact.team = @current_team
          company_id = r.params.dig("company", "id")
          @contact.company = @current_team.companies.with_hashid(company_id) if company_id

          if @contact.valid?
            @contact.save
            r.redirect "/contacts"
          else
            :contacts_new
          end
        end
      end

      r.on String do |id|
        @contact = @current_team.contacts.with_hashid(id)
        @companies = @current_team.companies

        if @contact.nil?
          response.status = 404
          r.halt
        end

        r.is "edit" do
          # CONTACTS EDIT
          # GET /contacts/:id/edit
          r.get do
            :contacts_edit
          end

          # CONTACTS UPDATE
          # POST /contacts/:id/edit
          r.post do
            @contact.set params(r)
            @contact.company = @companies.with_hashid(r.params["company_id"]) if r.params["company_id"]

            if @contact.valid?
              @contact.save
              r.redirect "/contacts"
            else
              :contacts_edit
            end
          end
        end

        # CONTACTS DELETE
        # POST /contacts/:id/delete
        r.post "delete" do
          @contact.delete
          r.redirect "/contacts"
        end
      end
    end
  end
end
