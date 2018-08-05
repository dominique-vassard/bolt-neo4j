defmodule BoltNeo4jTest do
  use BoltNeo4j.DatabaseCase

  alias BoltNeo4j.Bolt

  defmodule UnknownType do
    defstruct [:id]
  end

  test "Simple query without parameters", %{port: port, options: options} do
    res = Bolt.run_statement(:gen_tcp, port, "RETURN 1 AS num", %{}, options)

    assert [
             success: %{"fields" => ["num"], "result_available_after" => _},
             record: [1],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = res
  end

  test "Simple query with parameters", %{port: port, options: options} do
    res =
      Bolt.run_statement(
        :gen_tcp,
        port,
        "RETURN {str} AS return_string",
        %{
          str: "A gentle string!"
        },
        options
      )

    assert [
             success: %{"fields" => ["return_string"], "result_available_after" => _},
             record: ["A gentle string!"],
             success: %{"result_consumed_after" => _, "type" => "r"}
           ] = res
  end

  # TEST RETRIVED FROM BOLTEX
  # These test MUST pass as they are (except for the error module name which of course
  # will be BoltNeo4j and not Boltex)

  test "works for small queries", %{port: port, options: options} do
    string = Enum.to_list(0..100) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] = Bolt.run_statement(:gen_tcp, port, query, params, options)

    assert [record: [^string], success: _] = records
  end

  test "works for big queries", %{port: port, options: options} do
    string = Enum.to_list(0..25_000) |> Enum.join()

    query = """
      RETURN {string} as string
    """

    params = %{string: string}

    [{:success, _} | records] = Bolt.run_statement(:gen_tcp, port, query, params, options)

    assert [record: [^string], success: _] = records
  end

  test "returns errors for wrong cypher queris", %{port: port, options: options} do
    assert %BoltNeo4j.Error{type: :cypher_error} =
             Bolt.run_statement(:gen_tcp, port, "What?", %{}, options)
  end

  test "allows to recover from error with ack_failure", %{port: port, options: options} do
    assert %BoltNeo4j.Error{type: :cypher_error} =
             Bolt.run_statement(:gen_tcp, port, "What?", %{}, options)

    assert :ok = Bolt.ack_failure(:gen_tcp, port, options)

    assert [{:success, _} | _] =
             Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num", %{}, options)
  end

  test "allows to recover from error with reset", %{port: port, options: options} do
    assert %BoltNeo4j.Error{type: :cypher_error} =
             Bolt.run_statement(:gen_tcp, port, "What?", %{}, options)

    assert :ok = Bolt.reset(:gen_tcp, port, options)

    assert [{:success, _} | _] =
             Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num", %{}, options)
  end

  test "returns proper error when using a bad session", %{port: port, options: options} do
    assert %BoltNeo4j.Error{type: :cypher_error} =
             Bolt.run_statement(:gen_tcp, port, "What?", %{}, options)

    error = Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num", %{}, options)

    assert %BoltNeo4j.Error{} = error
    assert error.message =~ ~r/The session is in a failed state/
  end

  test "returns proper error when misusing ack_failure and reset", %{port: port, options: options} do
    assert %BoltNeo4j.Error{} = Bolt.ack_failure(:gen_tcp, port, options)
    :gen_tcp.close(port)
    assert %BoltNeo4j.Error{} = Bolt.reset(:gen_tcp, port, options)
  end

  test "returns proper error when using a closed port", %{port: port, options: options} do
    :gen_tcp.close(port)

    assert %BoltNeo4j.Error{type: :connection_error} =
             Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num", %{}, options)
  end

  test "works within a transaction", %{port: port, options: options} do
    assert [{:success, _}, {:success, _}] =
             Bolt.run_statement(:gen_tcp, port, "BEGIN", %{}, options)

    assert [{:success, _} | _] =
             Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num", %{}, options)

    assert [{:success, _}, {:success, _}] =
             Bolt.run_statement(:gen_tcp, port, "COMMIT", %{}, options)
  end

  test "works with rolled-back transactions", %{port: port, options: options} do
    assert [{:success, _}, {:success, _}] =
             Bolt.run_statement(:gen_tcp, port, "BEGIN", %{}, options)

    assert [{:success, _} | _] =
             Bolt.run_statement(:gen_tcp, port, "RETURN 1 as num", %{}, options)

    assert [{:success, _}, {:success, _}] =
             Bolt.run_statement(:gen_tcp, port, "ROLLBACK", %{}, options)
  end

  test "an invalid parameter value yields an error", %{port: port, options: options} do
    cypher = "MATCH (n:Person {invalid: {an_unknown_type}}) RETURN TRUE"

    assert_raise BoltNeo4j.Packstream.EncodeError, ~r/^unable to encode value: /i, fn ->
      Bolt.run_statement(:gen_tcp, port, cypher, %{an_unknown_type: %UnknownType{id: 3}}, options)
    end
  end
end
