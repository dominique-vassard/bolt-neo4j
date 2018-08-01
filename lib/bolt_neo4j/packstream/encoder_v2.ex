defmodule BoltNeo4j.Packstream.EncoderV2 do
  alias BoltNeo4j.Types.TimeWithTZ
  alias BoltNeo4j.Packstream.Encoder

  @tiny_struct_marker 0xB

  @date_marker 0x44
  @date_struct_size 1

  @time_marker 0x54
  @time_struct_size 2

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

  # Encode Time with Timezone
  @doc """
  Encode TimeWithTZ into Bolt Protocol binary

  ## Example:
      iex> ttz = %BoltNeo4j.Types.TimeWithTZ{time: ~T[12:45:30.250000], timezone_offset: 3600}
      %BoltNeo4j.Types.TimeWithTZ{time: ~T[12:45:30.250000], timezone_offset: 3600}
      iex> BoltNeo4j.Packstream.EncoderV2.encode_time_with_tz ttz, 2
      <<178, 84, 203, 0, 0, 41, 197, 248, 60, 86, 128, 201, 14, 16>>
  """
  def encode_time_with_tz(%TimeWithTZ{time: time, timezone_offset: offset}, version) do
    day_time = Time.diff(time, ~T[00:00:00.000], :nanosecond)

    <<@tiny_struct_marker::4, @time_struct_size::4, @time_marker>> <>
      Encoder.encode(day_time, version) <> Encoder.encode(offset, version)
  end
end
