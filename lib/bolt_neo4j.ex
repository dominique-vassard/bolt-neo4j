defmodule BoltNeo4j do
  @moduledoc """
  Elixir library for using the Neo4J Bolt Protocol.

  It supports de- and encoding of Boltex binaries and sending and receiving
  of data using the Bolt protocol.
  BoltNeo4j.test 'localhost', 7687, "RETURN date('2018-01-01') AS n", %{}, {"neo4j", "test"}
  """

  alias BoltNeo4j.Bolt

  def test(host, port, query, params \\ %{}, auth \\ {}, options \\ []) do
    {:ok, port_} = :gen_tcp.connect(host, port, active: false, mode: :binary, packet: :raw)

    {:ok, options} = Bolt.handshake(:gen_tcp, port_, options)
    {:ok, _info} = Bolt.init(:gen_tcp, port_, auth, options)

    Bolt.run_statement(:gen_tcp, port_, query, params, options)
  end
end
