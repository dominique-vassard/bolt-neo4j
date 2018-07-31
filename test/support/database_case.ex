defmodule BoltNeo4j.DatabaseCase do
  use ExUnit.CaseTemplate

  alias BoltNeo4j.Bolt

  setup do
    host = Application.get_env(:bolt_neo4j, :bolt_host) |> String.to_charlist()
    bolt_port = Application.get_env(:bolt_neo4j, :bolt_port)

    credentials =
      {Application.get_env(:bolt_neo4j, :user), Application.get_env(:bolt_neo4j, :password)}

    {:ok, port} = :gen_tcp.connect(host, bolt_port, active: false, mode: :binary, packet: :raw)
    {:ok, _} = Bolt.handshake(:gen_tcp, port)
    {:ok, _} = Bolt.init(:gen_tcp, port, credentials)

    on_exit(fn ->
      :gen_tcp.close(port)
    end)

    {:ok, port: port}
  end
end
