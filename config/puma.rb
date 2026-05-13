# frozen_string_literal: true

# ============================================================
# PUMA 8.0.1 — Productie configuratie
# Stack: Ruby 3.1.4 / Rails 7.1.5
# Hardware: 4 vCPU, 3.9 GiB RAM (container ~620 MiB baseline)
# ============================================================

# --- Threads ---
# Formule: min = max = RAILS_MAX_THREADS (match ActiveRecord pool)
# Met 2 workers × 5 threads = 10 gelijktijdige requests
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5).to_i
threads threads_count, threads_count

# --- Poort & binding ---
port ENV.fetch('PORT', 3000)

# --- Environment ---
environment ENV.fetch('RAILS_ENV', 'production')

# --- Workers (Cluster mode) ---
# Formule: aantal vCPU's - 1 (laat 1 CPU vrij voor OS/Postgres)
# Bij 4 vCPU → 2 workers is conservatief maar veilig voor 3.9 GiB RAM
# Elke worker ≈ 300-400 MiB → 2 workers = ~800 MiB + overhead = OK
workers ENV.fetch('WEB_CONCURRENCY', 2).to_i

# --- Copy-on-Write optimalisatie ---
preload_app!

# --- Worker boot: herverbind DB-connecties na fork ---
# Vervangt het deprecated 'before_worker_boot'
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# --- Timeouts ---
# worker_timeout: kill & herstart een worker die vastloopt (seconden)
worker_timeout 60

# --- Logging ---
# Structured logging naar stdout → Docker vangt dit op
# Gebruik RAILS_LOG_TO_STDOUT=true in je docker-compose / env
stdout_redirect '/dev/null', '/dev/stderr', true

# --- Lowlevel error handler ---
lowlevel_error_handler do |err, env|
  # Laat Puma zelf 500 terugsturen bij kritieke fouten
  [500, { 'Content-Type' => 'text/plain' }, ["Internal Server Error\n"]]
end

# --- Pidfile & state (nuttig voor graceful restart) ---
pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')
state_path ENV.fetch('STATE_PATH', 'tmp/pids/puma.state')

# --- Graceful shutdown ---
# Wacht max 30s op lopende requests bij SIGTERM
plugin :tmp_restart
