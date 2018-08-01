defmodule BoltNeo4j.Packstream.EncoderV2Test do
  use ExUnit.Case

  alias BoltNeo4j.Types.TimeWithTZ
  alias BoltNeo4j.Packstream.EncoderV2

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
  end
end
