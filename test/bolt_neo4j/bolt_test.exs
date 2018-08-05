defmodule BoltNeo4j.BoltTest do
  # use BoltNeo4j.UnitCase
  use ExUnit.Case

  alias BoltNeo4j.Bolt

  @host Application.get_env(:bolt_neo4j, :bolt_host) |> String.to_charlist()
  @port Application.get_env(:bolt_neo4j, :bolt_port)
  @user Application.get_env(:bolt_neo4j, :user)
  @pass Application.get_env(:bolt_neo4j, :password)

  describe "handshake/3:" do
    test "Valid for default version" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, [protocol_version: _, recv_timeout: _]} = Bolt.handshake(:gen_tcp, port_)
    end

    # test "Valid for version 2" do
    #   {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
    #   assert {:ok, 2} = Bolt.handshake(:gen_tcp, port_, protocol_version: 2)
    # end
  end

  describe "init/4:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)
    end

    test "invalid auth" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:error, _} = Bolt.init(:gen_tcp, port_, {@user, "wrong!"}, options)
    end
  end

  describe "ack_failure/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_, protocol_version: 1)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher", %{}, options)
      assert :ok = Bolt.ack_failure(:gen_tcp, port_, options)
    end
  end

  describe "run/5:" do
    test "ok without parameters" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)

      #  'result_available_after' and 'result_consumed_after' seems to be not available in Neo4j 3.0
      # assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
      #          Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)
      assert {:ok, %{"fields" => ["num"]}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)
    end

    test "ok with parameters" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)

      #  'result_available_after' and 'result_consumed_after' seems to be not available in Neo4j 3.0
      # assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
      #          Bolt.run(:gen_tcp, port_, "RETURN {num} AS num", %{num: 5}, options)
      assert {:ok, %{"fields" => ["num"]}} =
               Bolt.run(:gen_tcp, port_, "RETURN {num} AS num", %{num: 5}, options)
    end

    test "returns IGNORED when sending RUN on a FAILURE state" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher", %{}, options)

      assert {:error, _} = Bolt.pull_all(:gen_tcp, port_, options)
    end

    test "ok after IGNORED AND ACK_FAILURE" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher", %{}, options)

      {:error, _} = Bolt.pull_all(:gen_tcp, port_, options)
      :ok = Bolt.ack_failure(:gen_tcp, port_, options)

      #  'result_available_after' and 'result_consumed_after' seems to be not available in Neo4j 3.0
      # assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
      #          Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)
      assert {:ok, %{"fields" => ["num"]}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)

      {:ok, [{:record, _}, {:success, _}]} = Bolt.pull_all(:gen_tcp, port_, options)
    end
  end

  describe "pull_all/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)

      #  'result_available_after' and 'result_consumed_after' seems to be not available in Neo4j 3.0
      # assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
      #          Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)
      assert {:ok, %{"fields" => ["num"]}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)

      {:ok, [{:record, _}, {:success, _}]} = Bolt.pull_all(:gen_tcp, port_, options)
    end
  end

  describe "run_statement/5" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)
      res = Bolt.run_statement(:gen_tcp, port_, "MATCH (n) RETURN n", %{}, options)

      assert is_list(res)
    end
  end

  describe "discard_all/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)

      #  'result_available_after' and 'result_consumed_after' seems to be not available in Neo4j 3.0
      # assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
      #          Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)
      assert {:ok, %{"fields" => ["num"]}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)

      assert {:ok, _} = Bolt.discard_all(:gen_tcp, port_, options)
    end
  end

  describe "reset/3:" do
    test "ok" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)

      #  'result_available_after' and 'result_consumed_after' seems to be not available in Neo4j 3.0
      # assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
      #          Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)
      assert {:ok, %{"fields" => ["num"]}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)

      :ok = Bolt.reset(:gen_tcp, port_, options)
    end

    test "ok during process" do
      {:ok, port_} = :gen_tcp.connect(@host, @port, active: false, mode: :binary, packet: :raw)
      assert {:ok, options} = Bolt.handshake(:gen_tcp, port_)
      assert {:ok, _} = Bolt.init(:gen_tcp, port_, {@user, @pass}, options)
      assert {:error, _} = Bolt.run(:gen_tcp, port_, "Invalid cypher", %{}, options)

      {:error, _} = Bolt.pull_all(:gen_tcp, port_, options)
      :ok = Bolt.reset(:gen_tcp, port_, options)

      #  'result_available_after' and 'result_consumed_after' seems to be not available in Neo4j 3.0
      # assert {:ok, %{"fields" => ["num"], "result_available_after" => _r}} =
      #          Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)
      assert {:ok, %{"fields" => ["num"]}} =
               Bolt.run(:gen_tcp, port_, "RETURN 1 AS num", %{}, options)

      {:ok, [{:record, _}, {:success, _}]} = Bolt.pull_all(:gen_tcp, port_, options)
    end
  end
end
