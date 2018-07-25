defmodule BoltNeo4j.BoltTest do
  use BoltNeo4j.UnitCase

  alias BoltNeo4j.Bolt

  @host 'localhost'
  @port 7687

  describe "Bolt.handshake/3:" do
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
      assert_raise ArgumentError, fn -> Bolt.handshake(:gen_tcp, port_, protocol_version: -1) end
    end
  end

  describe "Bolt.init/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})
    end

    test "invalid auth" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:error, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "wrong!"})
    end
  end
end
