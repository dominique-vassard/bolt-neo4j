# BoltNeo4j

Elixir implementation of the Bolt protocol and corresponding PackStream
protocol. Both is being used by Neo4J.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bolt_neo4j` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bolt_neo4j, "~> 0.1.0"}
  ]
end
```

## Try it out!

```elixir
BoltNeo4j.test 'localhost', 7687, "MATCH (n) RETURN n"
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bolt_neo4j](https://hexdocs.pm/bolt_neo4j).

