defmodule BoltNeo4j.Packstream.EncoderV2 do
  alias BoltNeo4j.Types.{Duration, TimeWithTZ}
  alias BoltNeo4j.Packstream.Encoder

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
  Encode Date into Bolt protocol binary

  ## Example:
      EncoderV2.encode_date ~D[2018-01-05], 2
      <<177, 68, 201, 68, 128>>
  """
  def encode_date(date, version) do
    epoch = Date.diff(date, ~D[1970-01-01])

    <<@tiny_struct_marker::4, @date_struct_size::4, @date_marker>> <>
      Encoder.encode(epoch, version)
  end

  @doc """
  Encode TimeWithTZ into Bolt Protocol binary

  ## Example:
      iex> ttz = %BoltNeo4j.Types.TimeWithTZ{time: ~T[12:45:30.250000], timezone_offset: 3600}
      %BoltNeo4j.Types.TimeWithTZ{time: ~T[12:45:30.250000], timezone_offset: 3600}
      iex> EncoderV2.encode_time_with_tz ttz, 2
      <<178, 84, 203, 0, 0, 41, 197, 248, 60, 86, 128, 201, 14, 16>>
  """
  def encode_time_with_tz(%TimeWithTZ{time: time, timezone_offset: offset}, version) do
    <<@tiny_struct_marker::4, @time_struct_size::4, @time_marker>> <>
      Encoder.encode(day_time(time), version) <> Encoder.encode(offset, version)
  end

  @doc """
  Encode LOCAL TIME into Bolt protocol binary

  ## Example
      iex> EncoderV2.encode_local_time ~T[17:34:45], 2
      <<177, 116, 203, 0, 0, 57, 142, 175, 241, 210, 0>>
  """
  def encode_local_time(time, version) do
    <<@tiny_struct_marker::4, @local_time_struct_size::4, @local_time_marker>> <>
      Encoder.encode(day_time(time), version)
  end

  defp day_time(time) do
    Time.diff(time, ~T[00:00:00.000], :nanosecond)
  end

  @doc """
  Encode DURATION

  ## Example
    iex> duration = %BoltNeo4j.Types.Duration{days: 34, months: 15, nanoseconds: 5550, seconds: 54}
    %BoltNeo4j.Types.Duration{days: 34, months: 15, nanoseconds: 5550, seconds: 54}
    iex> EncoderV2.encode_duration duration,2
    <<180, 69, 15, 34, 54, 201, 21, 174>>
  """
  def encode_duration(
        %Duration{months: months, days: days, seconds: seconds, nanoseconds: nanoseconds},
        version
      ) do
    <<@tiny_struct_marker::4, @duration_struct_size::4, @duration_marker>> <>
      Encoder.encode(months, version) <>
      Encoder.encode(days, version) <>
      Encoder.encode(seconds, version) <> Encoder.encode(nanoseconds, version)
  end
end
