require "puma"

workers Integer(ENV["WEB_CONCURRENCY"] || 1)
threads_count = Integer(ENV["MAX_THREADS"] || 5)
threads threads_count, threads_count

environment ENV["RACK_ENV"] || "development"

if ENV["RACK_ENV"] == "production"
  bind "unix:///tmp/tinycrm.sock"
else
  rackup      DefaultRackup
  port        ENV["PORT"]     || 9001
end
