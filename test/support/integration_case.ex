defmodule BoltNeo4j.IntegrationCase do
  use ExUnit.CaseTemplate

  alias BoltNeo4j.UnitCase
  alias BoltNeo4j.Bolt

  setup do
    uri = UnitCase.neo4j_uri()
    port_opts = [active: false, mode: :binary, packet: :raw]
    {:ok, port} = :gen_tcp.connect(uri.host, uri.port, port_opts)
    :ok = Bolt.handshake(:gen_tcp, port)
    {:ok, _info} = Bolt.init(:gen_tcp, port, uri.userinfo)

    on_exit(fn ->
      :gen_tcp.close(port)
    end)

    {:ok, port: port}
  end
end
