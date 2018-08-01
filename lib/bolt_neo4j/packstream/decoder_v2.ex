defmodule BoltNeo4j.Packstream.DecoderV2 do
  alias BoltNeo4j.Packstream.Decoder
  alias BoltNeo4j.Types.TimeWithTZ

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

  @doc """
  Decode TIME

  Without specific decoding, result is as follow:
      iex> BoltNeo4j.test 'localhost', 7687, "RETURN time('12:45:30.25+01:00') AS t", %{}, {"neo4j", "test"}, [protocol_version: 2]
      [
        success: %{"fields" => ["t"], "result_available_after" => 7},
        record: [[sig: 84, fields: [45930250000000, 3600]]],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]

  Now, it is:
      [
        success: %{"fields" => ["t"], "result_available_after" => 0},
        record: [
          %BoltNeo4j.Types.TimeWithTZ{
            time: ~T[12:45:30.250000],
            timezone_offset: 3600
          }
        ],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]
  """
  def decode(
        <<@tiny_struct_marker::4, @time_struct_size::4, @time_marker::8, rest::binary>>,
        version
      ) do
    IO.puts(inspect(Decoder.decode(rest, version)))

    {[time, offset], rest_dec} =
      rest
      |> Decoder.decode(version)
      |> Enum.split(2)

    t = %TimeWithTZ{time: Time.add(~T[00:00:00.000], time, :nanosecond), timezone_offset: offset}
    [t | rest_dec]
  end

  def decode(_, _) do
    {:error, "Not implemented"}
  end
end
