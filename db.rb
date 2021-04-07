require "sequel/core"

DB = Sequel.sqlite ENV.fetch("DATABASE_URL", "db.sqlite3")
