defmodule BoltNeo4j.DecoderV2Test do
  use ExUnit.Case

  alias BoltNeo4j.Types.TimeWithTZ
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
  end
end
