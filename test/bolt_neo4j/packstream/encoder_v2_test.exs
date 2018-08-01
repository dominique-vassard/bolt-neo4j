defmodule BoltNeo4j.Packstream.EncoderV2Test do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.EncoderV2

  describe "Encode temporal types:" do
    test "date post 1970-01-01" do
      assert <<0xB1, 0x44, 0xC9, 0x45, 0x4D>> = EncoderV2.encode_date(~D[2018-07-29], 2)
    end

    test "date pre 1970-01-01" do
      assert <<0xB1, 0x44, 0xC9, 0xB6, 0xA0>> = EncoderV2.encode_date(~D[1918-07-29], 2)
    end
  end
end
