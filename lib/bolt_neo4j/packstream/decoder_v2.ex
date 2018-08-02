defmodule BoltNeo4j.Packstream.DecoderV2 do
  alias BoltNeo4j.Packstream.{Decoder, Helper}
  alias BoltNeo4j.Types.{DateTimeWithOffset, Duration, TimeWithTZ}

  @tiny_struct_marker 0xB

  @date_marker 0x44
  @date_struct_size 1

  @time_marker 0x54
  @time_struct_size 2

  @local_time_marker 0x74
  @local_time_struct_size 1

  @duration_marker 0x45
  @duration_struct_size 4

  @local_datetime_marker 0x64
  @local_datetime_struct_size 2

  @datetime_with_zone_offset_marker 0x46
  @datetime_with_zone_offset_struct_size 3

  @datetime_with_zone_id_marker 0x66
  @datetime_with_zone_id_struct_size 3

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

  @doc """
  Decode LOCAL DATETIME

  WARNING: Nanoseconds are lost as NaiveDateTime is only able to manange microseconds!

  Without specific decoding, result is as follow:
      iex> BoltNeo4j.test 'localhost', 7687, "RETURN localdatetime('2018-04-05T12:34:00.543') AS d", %{}, {"neo4j", "test"}, [protocol_version: 2]
      [
        success: %{"fields" => ["d"], "result_available_after" => 6},
        record: [[sig: 100, fields: [1522931640, 543000000]]],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]

  Now it is
      [
        success: %{"fields" => ["d"], "result_available_after" => 6},
        record: [~N[2018-04-05 12:34:00.543]],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]
  """
  def decode(
        <<@tiny_struct_marker::4, @local_datetime_struct_size::4, @local_datetime_marker,
          data::binary>>,
        version
      ) do
    {dt, rest} = extract_naivedatetime(data, version)
    [dt | rest]
  end

  @doc """
  Decode DATETIME WITH ZONE OFFSET

  WARNING: Nanoseconds are lost as NaiveDateTime is only able to manange microseconds!

  Without specific decoding, result is as follow:
      iex> BoltNeo4j.test 'localhost', 7687, "RETURN datetime('2018-04-05T12:34:23.543+01:00') AS d", %{}, {"neo4j", "test"}, [protocol_version: 2]
      [
        success: %{"fields" => ["d"], "result_available_after" => 6},
        record: [[sig: 70, fields: [1522931663, 543000000, 3600]]],
        success: %{"result_consumed_after" => 0, "type" => "r"}
      ]
  Now it is:
      [
      success: %{"fields" => ["d"], "result_available_after" => 1},
      record: [
        %BoltNeo4j.Types.DateTimeWithOffset{
          naive_datetime: ~N[2018-04-05 12:34:23.543],
          timezone_offset: 3600
        }
      ]
  """
  def decode(
        <<@tiny_struct_marker::4, @datetime_with_zone_offset_struct_size::4,
          @datetime_with_zone_offset_marker, data::binary>>,
        version
      ) do
    {datetime, rest} = extract_datetime(data, version)
    [datetime | rest]
  end

  @doc """
  Decode DATETIME WITH ZONE ID

  WARNING: Nanoseconds are lost as NaiveDateTime is only able to manange microseconds!

  Without specific decoding, result is as follow:
      iex> BoltNeo4j.test 'localhost', 7687, "RETURN datetime('2018-04-05T12:34:23.543[Europe/Berlin]') AS d", %{}, {"neo4j", "test"}, [protocol_version: 2]
      [
        success: %{"fields" => ["d"], "result_available_after" => 11},
        record: [[sig: 102, fields: [1522931663, 543000000, "Europe/Berlin"]]],
        success: %{"result_consumed_after" => 1, "type" => "r"}
      ]

      Now, it is:
      [
        success: %{"fields" => ["d"], "result_available_after" => 0},
        record: [#DateTime<2018-04-05 12:34:23.543+02:00 CEST Europe/Berlin>],
        success: %{"result_consumed_after" => 1, "type" => "r"}
      ]
  """
  def decode(
        <<@tiny_struct_marker::4, @datetime_with_zone_id_struct_size::4,
          @datetime_with_zone_id_marker, data::binary>>,
        version
      ) do
    {datetime, rest} = extract_datetime(data, version)
    [datetime | rest]
  end

  def decode(_, _) do
    {:error, "Not implemented"}
  end

  defp extract_datetime(data, version) do
    {naive_dt, [tz_data | rest]} = extract_naivedatetime(data, version)

    {create_datetime(naive_dt, tz_data), rest}
  end

  defp create_datetime(naive_dt, tz_data) when is_integer(tz_data) do
    %DateTimeWithOffset{naivedatetime: naive_dt, timezone_offset: tz_data}
  end

  defp create_datetime(naive_dt, tz_data) do
    Helper.datetime_with_micro(naive_dt, tz_data)
  end

  defp extract_naivedatetime(data, version) do
    {[seconds, nanoseconds], rest} =
      data
      |> Decoder.decode(version)
      |> Enum.split(2)

    naive_dt =
      NaiveDateTime.add(
        ~N[1970-01-01 00:00:00.000],
        seconds * 1_000_000_000 + nanoseconds,
        :nanosecond
      )

    {naive_dt, rest}
  end
end
