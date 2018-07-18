defmodule BoltNeo4j.BoltTest do
  use BoltNeo4j.UnitCase

  alias BoltNeo4j.Bolt

  @host 'localhost'
  @port 7687

  describe "Bolt.handshake/3" do
    test "Valid for default version" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_)
    end

    test "Valid for version 2" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 2} = Bolt.handshake(:gen_tcp, port_, protocol_version: 2)
    end

    test "Crash for invalid version" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:error, _} = Bolt.handshake(:gen_tcp, port_, protocol_version: -1)
    end
  end
end