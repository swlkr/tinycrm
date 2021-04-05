require "roda"
require "sequel"
require "dotenv/load"
require "securerandom"
require "puma"
require "zeitwerk"
require "listen"

$stdout.sync = true

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.enable_reloading
loader.setup

Listen.to(__dir__, only: /\.rb$/, force_polling: true) { loader.reload }.start

run ->(env) {
  loader.reload
  App.call(env)
}



