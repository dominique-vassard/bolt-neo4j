use Mix.Config

config :logger,
  compile_time_purge_level: :debug

config :bolt_neo4j,
  bolt_host: System.get_env("NEO4J_BOLT_HOST") || "localhost",
  bolt_port: System.get_env("NEO4J_BOLT_PORT") || 7687,
  user: System.get_env("NEO4j_USER") || "neo4j",
  password: System.get_env("NEO4J_PASS") || "test"
