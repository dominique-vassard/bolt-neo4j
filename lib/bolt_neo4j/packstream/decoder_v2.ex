defmodule BoltNeo4j.Packstream.DecoderV2 do
  alias BoltNeo4j.Packstream.Decoder

  @tiny_struct_marker 0xB

  @date_marker 0x44
  @date_struct_size 1

  @time_marker 0x54
  @time_struct_size 2

  @doc """
  Decode DATE

  Without specific decoding, result is as follow:
      iex> BoltNeo4j.test 'localhost', 7687, "RETURN date('2017-01-01') AS d", %{}, {"neo4j", "test"}, [protocol_version: 2]
      [
        success: %{"fields" => ["d"], "result_available_after" => 0},
        record: [[sig: 68, fields: [17167]]],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]

  Now, it is:
      [
        success: %{"fields" => ["d"], "result_available_after" => 0},
        record: [~D[2017-01-01]],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]
  """
  def decode(
        <<@tiny_struct_marker::4, @date_struct_size::4, @date_marker::8, rest::binary>>,
        version
      ) do
    [date | rest_dec] = Decoder.decode(rest, version)
    [Date.add(~D[1970-01-01], date) | rest_dec]
  end

  def decode(_, _) do
    {:error, "Not implemented"}
  end
end
