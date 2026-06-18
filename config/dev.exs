import Config

# Enables the dev-only routes mounted by the Oban Powertools router macro
# (e.g. the brand book LiveView at /ops/jobs/_brand_book). Evaluated at the
# host's compile time via Application.compile_env/3 — see the router macro and
# ObanPowertools.Web.Dev.BrandBookLive. Absent from config/prod.exs so the
# route defaults to false (Mix.env() == :dev fallback) in production builds.
config :oban_powertools, dev_routes: true
