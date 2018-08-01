defmodule BoltNeo4j.DecoderV2Test do
  use ExUnit.Case

  alias BoltNeo4j.Types.{Duration, TimeWithTZ}
  alias BoltNeo4j.Packstream.DecoderV2

  describe "Decode temporal data:" do
    test "date post 1970-01-01" do
      assert [~D[2018-07-29]] = DecoderV2.decode(<<0xB1, 0x44, 0xC9, 0x45, 0x4D>>, 2)
    end

    test "date pre 1970-01-01" do
      assert [~D[1918-07-29]] = DecoderV2.decode(<<0xB1, 0x44, 0xC9, 0xB6, 0xA0>>, 2)
    end

    test "time with timezone offset" do
      assert [
               %TimeWithTZ{
                 time: ~T[12:45:30.250000],
                 timezone_offset: 3600
               }
             ] =
               DecoderV2.decode(
                 <<0xB2, 0x54, 0xCB, 0x0, 0x0, 0x29, 0xC5, 0xF8, 0x3C, 0x56, 0x80, 0xC9, 0xE,
                   0x10>>,
                 2
               )
    end

    test "time without timezone" do
      assert [~T[17:34:45.000000]] =
               DecoderV2.decode(
                 <<0xB1, 0x74, 0xCB, 0x0, 0x0, 0x39, 0x8E, 0xAF, 0xF1, 0xD2, 0x0>>,
                 2
               )
    end

    test "duration with all values" do
      assert [%Duration{days: 34, months: 15, nanoseconds: 5550, seconds: 54}] =
               DecoderV2.decode(<<0xB4, 0x45, 0xF, 0x22, 0x36, 0xC9, 0x15, 0xAE>>, 2)
    end
  end
end
