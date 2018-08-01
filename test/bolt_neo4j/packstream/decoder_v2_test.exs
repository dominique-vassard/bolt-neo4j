defmodule BoltNeo4j.DecoderV2Test do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.DecoderV2

  describe "Decode temporal data:" do
    test "date post 1970-01-01" do
      assert [~D[2018-07-29]] = DecoderV2.decode(<<0xB1, 0x44, 0xC9, 0x45, 0x4D>>, 2)
    end

    test "date pre 1970-01-01" do
      assert [~D[1918-07-29]] = DecoderV2.decode(<<0xB1, 0x44, 0xC9, 0xB6, 0xA0>>, 2)
    end
  end
end
