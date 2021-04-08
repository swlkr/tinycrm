require "dotenv/load"
require "roda"
require "sequel"
require "securerandom"
require "puma"
require "zeitwerk"
require "listen"
require "./db"
require "./models"

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.enable_reloading
loader.setup

Listen.to(__dir__, only: /(\.rb|\.mab)$/, force_polling: true) { loader.reload }.start

run ->(env) {
  loader.reload
  App.call(env)
}
