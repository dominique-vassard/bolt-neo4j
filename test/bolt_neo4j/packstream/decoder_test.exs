defmodule BoltNeo4j.Packstream.DecoderTest do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.Decoder

  test "Decode <<0xC0>> to  nil in v1" do
    assert nil == Decoder.decode(<<0xC0>>)
  end

  test "Decode <<0xC0>> to  nil in v2" do
    assert nil == Decoder.decode(<<0xC0>>, 2)
  end

  test "Decode <<0x2A>> to  42 in v1" do
    assert 42 = Decoder.decode(<<0x2A>>)
  end

  test "Decode <<0x2A>> to  42 in v2" do
    assert 42 = Decoder.decode(<<0x2A>>, 2)
  end
end
