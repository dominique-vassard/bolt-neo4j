defmodule BoltNeo4j.BoltTest do
  use BoltNeo4j.UnitCase

  alias BoltNeo4j.Bolt

  @host 'localhost'
  @port 7687

  describe "handshake/3:" do
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

  describe "init/4:" do
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

  # TEST TO BE DONE!
  describe "ack_failure/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher")
      assert({:ok, _} = Bolt.ack_failure(:gen_tcp, port_))
    end
  end

  describe "run/5:" do
    test "ok without parameters" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})

      assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num")
    end

    test "ok with parameters" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})

      assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
               Bolt.run(:gen_tcp, port_, "RETURN {num} AS num", %{num: 5})
    end

    test "returns IGNORED when sending RUN on a FAILURE state" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher")

      assert {:error, _} = Bolt.pull_all(:gen_tcp, port_)
    end

    test "ok after IGNORED AND ACK_FAILURE" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher")

      {:error, _} = Bolt.pull_all(:gen_tcp, port_)
      {:ok, _} = Bolt.ack_failure(:gen_tcp, port_)

      assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num")

      {:ok, [{:record, _}, {:success, _}]} = Bolt.pull_all(:gen_tcp, port_)
    end
  end

  describe "pull_all/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})

      assert {:ok, %{"fields" => ["num"], "result_available_after" => _}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num")

      {:ok, [{:record, _}, {:success, _}]} = Bolt.pull_all(:gen_tcp, port_)
    end
  end

  describe "run_statement/5" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})
      res = Bolt.run_statement(:gen_tcp, port_, "MATCH (n) RETURN n")

      assert is_list(res)
    end
  end

  describe "discard_all/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})

      assert {:ok, %{"fields" => ["num"], "result_available_after" => _}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num")

      assert {:ok, _} = Bolt.discard_all(:gen_tcp, port_)
    end
  end

  describe "reset/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})

      assert {:ok, %{"fields" => ["num"], "result_available_after" => _}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num")

      {:ok, _} = Bolt.reset(:gen_tcp, port_)
    end

    test "ok during process" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, 1} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {"neo4j", "test"})
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher")

      {:error, _} = Bolt.pull_all(:gen_tcp, port_)
      {:ok, _} = Bolt.reset(:gen_tcp, port_)

      assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num")

      {:ok, [{:record, _}, {:success, _}]} = Bolt.pull_all(:gen_tcp, port_)
    end
  end
end
