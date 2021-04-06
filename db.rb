require "sequel/core"

DB = Sequel.sqlite ENV.fetch("DATABASE_URL", "db.sqlite3")

User = DB[:users]
Company = DB[:companies]
Contact = DB[:contacts]
Deal = DB[:deals]
DealStage = DB[:deals_stages]
