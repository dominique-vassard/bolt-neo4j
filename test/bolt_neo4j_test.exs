defmodule BoltNeo4jTest do
  use BoltNeo4j.DatabaseCase

  alias BoltNeo4j.Bolt

  test "Simple query without parameters", %{port: port} do
    res = Bolt.run_statement(:gen_tcp, port, "RETURN 1 AS num", %{})

    assert [
             success: %{"fields" => ["num"], "result_available_after" => _},
             record: [1],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = res
  end

  test "Simple query with parameters", %{port: port} do
    res =
      Bolt.run_statement(:gen_tcp, port, "RETURN {str} AS return_string", %{
        str: "A gentle string!"
      })

    assert [
             success: %{"fields" => ["return_string"], "result_available_after" => _},
             record: ["A gentle string!"],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = res
  end

  # TEST RETRIVED FROM BOLTEX
  # These test MUST pass as they are (except for the error module name which of course
  # will be BoltNeo4j and not Boltex)

  test "works for small queries", %{port: port} do
    string = Enum.to_list(0..100) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] = Bolt.run_statement(:gen_tcp, port, query, params)

    assert [record: [^string], success: _] = records
  end

  test "works for big queries", %{port: port} do
    string = Enum.to_list(0..25_000) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] = Bolt.run_statement(:gen_tcp, port, query, params)

    assert [record: [^string], success: _] = records
  end

  test "returns errors for wrong cypher queris", %{port: port} do
    assert %BoltNeo4j.Error{type: :cypher_error} = Bolt.run_statement(:gen_tcp, port, "What?")
  end

  test "allows to recover from error with ack_failure", %{port: port} do
    assert %BoltNeo4j.Error{type: :cypher_error} = Bolt.run_statement(:gen_tcp, port, "What?")
    assert :ok = Bolt.ack_failure(:gen_tcp, port)
    assert [{:success, _} | _] = Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num")
  end

  test "allows to recover from error with reset", %{port: port} do
    assert %BoltNeo4j.Error{type: :cypher_error} = Bolt.run_statement(:gen_tcp, port, "What?")
    assert :ok = Bolt.reset(:gen_tcp, port)
    assert [{:success, _} | _] = Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num")
  end

  test "returns proper error when using a bad session", %{port: port} do
    assert %BoltNeo4j.Error{type: :cypher_error} = Bolt.run_statement(:gen_tcp, port, "What?")
    error = Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num")

    assert %BoltNeo4j.Error{} = error
    assert error.message =~ ~r/The session is in a failed state/
  end

  test "returns proper error when misusing ack_failure and reset", %{port: port} do
    assert %BoltNeo4j.Error{} = Bolt.ack_failure(:gen_tcp, port)
    :gen_tcp.close(port)
    assert %BoltNeo4j.Error{} = Bolt.reset(:gen_tcp, port)
  end

  test "returns proper error when using a closed port", %{port: port} do
    :gen_tcp.close(port)

    assert %BoltNeo4j.Error{type: :connection_error} =
             Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num")
  end

  test "works within a transaction", %{port: port} do
    assert [{:success, _}, {:success, _}] = Bolt.run_statement(:gen_tcp, port, "BEGIN")
    assert [{:success, _} | _] = Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num")
    assert [{:success, _}, {:success, _}] = Bolt.run_statement(:gen_tcp, port, "COMMIT")
  end

  test "works with rolled-back transactions", %{port: port} do
    assert [{:success, _}, {:success, _}] = Bolt.run_statement(:gen_tcp, port, "BEGIN")
    assert [{:success, _} | _] = Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num")
    assert [{:success, _}, {:success, _}] = Bolt.run_statement(:gen_tcp, port, "ROLLBACK")
  end

  test "an invalid parameter value yields an error", %{port: port} do
    cypher = "MATCH (n:Person {invalid: {an_elixir_datetime}}) RETURN TRUE"

    assert_raise BoltNeo4j.Packstream.EncodeError, ~r/^unable to encode value: /i, fn ->
      Bolt.run_statement(:gen_tcp, port, cypher, %{an_elixir_datetime: DateTime.utc_now()})
    end
  end
end
