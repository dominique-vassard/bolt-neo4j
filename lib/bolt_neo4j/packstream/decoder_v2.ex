defmodule BoltNeo4j.Packstream.DecoderV2 do
  alias BoltNeo4j.Packstream.Decoder
  alias BoltNeo4j.Types.{Duration, TimeWithTZ}

  @tiny_struct_marker 0xB

  @date_marker 0x44
  @date_struct_size 1

  @time_marker 0x54
  @time_struct_size 2

  @local_time_marker 0x74
  @local_time_struct_size 1

  @duration_marker 0x45
  @duration_struct_size 4

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
    {[time, offset], rest_dec} =
      rest
      |> Decoder.decode(version)
      |> Enum.split(2)

    t = %TimeWithTZ{time: Time.add(~T[00:00:00.000], time, :nanosecond), timezone_offset: offset}
    [t | rest_dec]
  end

  @doc """
  Decode LOCAL TIME

  Without specific decoding, result is as follow:
      iex> BoltNeo4j.test 'localhost', 7687, "RETURN local_time('12:45:30.25') AS t", %{}, {"neo4j", "test"}, [protocol_version: 2]
      [
        success: %{"fields" => ["t"], "result_available_after" => 0},
        record: [[sig: 116, fields: [45930250000000]]],
        success: %{"result_consumed_after" => 1, "type" => "r"}
      ]

  Now, it is:
      [
        success: %{"fields" => ["t"], "result_available_after" => 0},
        record: [~T[12:45:30.250000]],
        success: %{"result_consumed_after" => 1, "type" => "r"}
      ]
  """
  def decode(
        <<@tiny_struct_marker::4, @local_time_struct_size::4, @local_time_marker, rest::binary>>,
        version
      ) do
    [time | rest_desc] = Decoder.decode(rest, version)
    [Time.add(~T[00:00:00.000], time, :nanosecond) | rest_desc]
  end

  @doc """
  Decode DURATION

  Without specific decoding, result is as follow:
      iex> BoltNeo4j.test 'localhost', 7687, "RETURN duration('P1Y3M34DT54.00000555S') AS d", %{}, {"neo4j", "test"}, [protocol_version: 2]
      [
        success: %{"fields" => ["d"], "result_available_after" => 1},
        record: [[sig: 69, fields: [15, 34, 54, 5550]]],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]

  Now, it is:
      [
        success: %{"fields" => ["d"], "result_available_after" => 8},
        record: [
          %BoltNeo4j.Types.Duration{
            days: 34,
            months: 15,
            nanoseconds: 5550,
            seconds: 54
          }
        ],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]
  """
  def decode(
        <<@tiny_struct_marker::4, @duration_struct_size::4, @duration_marker, rest::binary>>,
        version
      ) do
    {[months, days, seconds, nanoseconds], rest_dec} =
      rest
      |> Decoder.decode(version)
      |> Enum.split(@duration_struct_size)

    [%Duration{months: months, days: days, seconds: seconds, nanoseconds: nanoseconds} | rest_dec]
  end

  def decode(_, _) do
    {:error, "Not implemented"}
  end
end
