defmodule BoltNeo4j.Packstream.EncoderV2 do
  alias BoltNeo4j.Types.{DateTimeWithOffset, Duration, TimeWithTZ, Point}
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

  @local_datetime_marker 0x64
  @local_datetime_struct_size 2

  @datetime_with_zone_offset_marker 0x46
  @datetime_with_zone_offset_struct_size 3

  @datetime_with_zone_id_marker 0x66
  @datetime_with_zone_id_struct_size 3

  @point2d_marker 0x58
  @point2d_struct_size 3

  @point3d_marker 0x59
  @point3d_struct_size 4

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

  @doc """
  Encode LOCAL DATETIME

  WARNING: Nanoseconds are lef off as NaiveDateTime doesn't handle them.
  A new Calendar should be implemented to manage them

  ## Example
      iex> EncoderV2.encode_local_datetime ~N[2018-04-05 12:34:00.543], 2
      <<178, 100, 202, 90, 198, 23, 184, 202, 32, 93, 133, 192>>
  """
  def encode_local_datetime(local_datetime, version) do
    datetime = NaiveDateTime.diff(local_datetime, ~N[1970-01-01 00:00:00.000], :microsecond)

    sec = div(datetime, 1_000_000)
    nanosec = rem(datetime, 1_000_000) * 1_000

    <<@tiny_struct_marker::4, @local_datetime_struct_size::4, @local_datetime_marker>> <>
      Encoder.encode(sec, version) <> Encoder.encode(nanosec, version)
  end

  @doc """
  Encode DATETIME WITH TIMEZONE ID

  WARNING: Nanoseconds are lef off as NaiveDateTime doesn't handle them.
  A new Calendar should be implemented to manage them

  ## Example
      iex> dt = BoltNeo4j.Packstream.Helper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Berlin")
      #DateTime<2016-05-24 13:26:08.543+02:00 CEST Europe/Berlin>
      iex> EncoderV2.encode_datetime_with_tz dt, 2
      <<179, 102, 202, 87, 68, 86, 112, 202, 32, 93, 133, 192, 141, 69, 117, 114, 111,
        112, 101, 47, 66, 101, 114, 108, 105, 110>>
  """
  def encode_datetime_with_tz(datetime, version) do
    <<@tiny_struct_marker::4, @datetime_with_zone_id_struct_size::4,
      @datetime_with_zone_id_marker>> <>
      encode_datetime(DateTime.to_naive(datetime), version) <>
      Encoder.encode(datetime.time_zone, version)
  end

  @doc """
  Encode DATETIME WITH TIMEZONE OFFSET

  WARNING: Nanoseconds are lef off as NaiveDateTime doesn't handle them.
  A new Calendar should be implemented to manage them

  ## Example
      iex> dt = %BoltNeo4j.Types.DateTimeWithOffset{naivedatetime: ~N[2016-05-24 13:26:08.543], timezone_offset: 7200}
      %BoltNeo4j.Types.DateTimeWithOffset{
        naivedatetime: ~N[2016-05-24 13:26:08.543],
        timezone_offset: 7200
      }
      iex> EncoderV2.encode_datetime_with_offset dt, 2
      <<179, 70, 202, 87, 68, 86, 112, 202, 32, 93, 133, 192, 201, 28, 32>>
  """
  def encode_datetime_with_offset(
        %DateTimeWithOffset{naivedatetime: ndt, timezone_offset: tz_offset},
        version
      ) do
    <<@tiny_struct_marker::4, @datetime_with_zone_offset_struct_size::4,
      @datetime_with_zone_offset_marker>> <>
      encode_datetime(ndt, version) <> Encoder.encode(tz_offset, version)
  end

  @doc """
  Encode POINT 2D

  ## Example (cartesian)
      iex> EncoderV2.encode_point BoltNeo4j.Types.Point.create(:cartesian, 40, 45), 2
      <<179, 88, 201, 28, 35, 193, 64, 68, 0, 0, 0, 0, 0, 0, 193, 64, 70, 128, 0, 0,
        0, 0, 0>>

  ## Example (geographic)
      iex> EncoderV2.encode_point BoltNeo4j.Types.Point.create(:wgs_84, 40, 45), 2
      <<179, 88, 201, 16, 230, 193, 64, 68, 0, 0, 0, 0, 0, 0, 193, 64, 70, 128, 0, 0,
        0, 0, 0>>

  """
  def encode_point(%Point{z: nil} = point, version) do
    <<@tiny_struct_marker::4, @point2d_struct_size::4, @point2d_marker>> <>
      Encoder.encode(point.srid, version) <>
      Encoder.encode(point.x, version) <> Encoder.encode(point.y, version)
  end

  @doc """
  Encode POINT 3D

  ## Example (cartesian)
      iex> EncoderV2.encode_point Point.create(:cartesian, 40, 45, 150), 2
      <<180, 89, 201, 35, 197, 193, 64, 68, 0, 0, 0, 0, 0, 0, 193, 64, 70, 128, 0, 0,
      0, 0, 0, 193, 64, 98, 192, 0, 0, 0, 0, 0>>

  ## Example (geographic)
      iex> EncoderV2.encode_point BoltNeo4j.Types.Point.create(:wgs_84, 40, 45, 150), 2
      <<180, 89, 201, 19, 115, 193, 64, 68, 0, 0, 0, 0, 0, 0, 193, 64, 70, 128, 0, 0,
        0, 0, 0, 193, 64, 98, 192, 0, 0, 0, 0, 0>>
  """
  def encode_point(point, version) do
    <<@tiny_struct_marker::4, @point3d_struct_size::4, @point3d_marker>> <>
      Encoder.encode(point.srid, version) <>
      Encoder.encode(point.x, version) <>
      Encoder.encode(point.y, version) <> Encoder.encode(point.z, version)
  end

  defp encode_datetime(%NaiveDateTime{} = datetime, version) do
    datetime_micros = NaiveDateTime.diff(datetime, ~N[1970-01-01 00:00:00.000], :microsecond)

    sec = div(datetime_micros, 1_000_000)
    nanosec = rem(datetime_micros, 1_000_000) * 1_000

    Encoder.encode(sec, version) <> Encoder.encode(nanosec, version)
  end
end
