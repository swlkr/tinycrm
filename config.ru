require "dotenv/load"
require "sequel"
require "./db"
require "./models"
require "roda"
require "securerandom"
require "puma"
require "zeitwerk"
require "listen"

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.push_dir("#{__dir__}/models")
loader.enable_reloading
loader.setup

Listen.to(__dir__, "#{__dir__}/models", only: /\.rb$/, force_polling: true) { loader.reload }.start

run ->(env) {
  loader.reload
  App.call(env)
}



