# BoltNeo4j

Elixir implementation of the Bolt protocol and corresponding PackStream
protocol. Both is being used by Neo4J.

Share some code with the original Boltex: https://github.com/mschae/boltex  
This is a implementation closer to the Neo4j official drivers.  
It implements Bolt V2 by reverse engineering Neo4j Python and JS official drivers.  
Has more logs than the Boltex implementation.  

WARNING: It is NOT production-ready  
And some merge with Boltex needs to be done in order to only have one driver for Elixir.  
  
[x] BoltNeo4j has exactly the same feadtures and output as Boltex
[] Implement Neo4j Bolt v2

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
