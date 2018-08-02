defmodule BoltNeo4j.Packstream.EncoderV2Test do
  use ExUnit.Case

  alias BoltNeo4j.Types.{DateTimeWithOffset, Duration, TimeWithTZ}
  alias BoltNeo4j.Packstream.EncoderV2
  alias BoltNeo4j.Packstream.Helper

  describe "Encode temporal types:" do
    test "date post 1970-01-01" do
      assert <<0xB1, 0x44, 0xC9, 0x45, 0x4D>> = EncoderV2.encode_date(~D[2018-07-29], 2)
    end

    test "date pre 1970-01-01" do
      assert <<0xB1, 0x44, 0xC9, 0xB6, 0xA0>> = EncoderV2.encode_date(~D[1918-07-29], 2)
    end

    test "time with timezone" do
      ttz = %TimeWithTZ{
        time: ~T[12:45:30.250000],
        timezone_offset: 3600
      }

      assert <<0xB2, 0x54, 0xCB, 0x0, 0x0, 0x29, 0xC5, 0xF8, 0x3C, 0x56, 0x80, 0xC9, 0xE, 0x10>> =
               EncoderV2.encode_time_with_tz(ttz, 2)
    end

    test "time without timezone" do
      assert <<0xB1, 0x74, 0xCB, 0x0, 0x0, 0x39, 0x8E, 0xAF, 0xF1, 0xD2, 0x0>> =
               EncoderV2.encode_local_time(~T[17:34:45], 2)
    end

    test "duration with all values" do
      duration = %Duration{days: 34, months: 15, nanoseconds: 5550, seconds: 54}

      assert <<0xB4, 0x45, 0xF, 0x22, 0x36, 0xC9, 0x15, 0xAE>> =
               EncoderV2.encode_duration(duration, 2)
    end

    test "local datetime" do
      assert <<0xB2, 0x64, 0xCA, 0x5A, 0xC6, 0x17, 0xB8, 0xCA, 0x20, 0x5D, 0x85, 0xC0>> =
               EncoderV2.encode_local_datetime(~N[2018-04-05 12:34:00.543], 2)
    end

    test "datetime with timezone id" do
      dt = Helper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Berlin")

      assert <<0xB3, 0x66, 0xCA, 0x57, 0x44, 0x56, 0x70, 0xCA, 0x20, 0x5D, 0x85, 0xC0, 0x8D, 0x45,
               0x75, 0x72, 0x6F, 0x70, 0x65, 0x2F, 0x42, 0x65, 0x72, 0x6C, 0x69,
               0x6E>> = EncoderV2.encode_datetime_with_tz(dt, 2)
    end

    test "datetime with timezone offset" do
      dt = %DateTimeWithOffset{naivedatetime: ~N[2016-05-24 13:26:08.543], timezone_offset: 7200}

      assert <<0xB3, 0x46, 0xCA, 0x57, 0x44, 0x56, 0x70, 0xCA, 0x20, 0x5D, 0x85, 0xC0, 0xC9, 0x1C,
               0x20>> = EncoderV2.encode_datetime_with_offset(dt, 2)
    end
  end
end
