require "dotenv/load"
require "roda"
require "sequel"
require "haikunator"
require "zeitwerk"
require "listen"

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.push_dir("#{__dir__}/models")

rack_env = ENV["RACK_ENV"]

if rack_env != "production"
  loader.enable_reloading
  loader.setup

  Listen.to(__dir__, "#{__dir__}/models", only: /(\.rb|\.mab)$/, force_polling: true) { loader.reload }.start

  run ->(env) {
    loader.reload
    App.call(env)
  }
else
  loader.setup

  run ->(env) {
    App.call(env)
  }
end
