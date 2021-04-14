require "puma"

workers Integer(ENV["WEB_CONCURRENCY"] || 1)
threads_count = Integer(ENV["MAX_THREADS"] ||1)
threads threads_count, threads_count


if ENV["RACK_ENV"] == "production"
  bind "unix:///tmp/tinycrm.sock"
  environment ENV["RACK_ENV"] || "development"
else
  rackup      DefaultRackup
  port        ENV["PORT"]     || 9001
  environment ENV["RACK_ENV"] || "development"
end
