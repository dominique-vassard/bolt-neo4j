defmodule BoltNeo4j.Packstream.EncoderTest do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.Encoder

  test "Encode nil in v1" do
    assert <<0xC0>> = Encoder.encode(nil)
  end

  test "Encode nil in v2" do
    assert <<0xC0>> = Encoder.encode(nil, 2)
  end

  test "Encode tiny list in v1" do
    assert <<0x94, 0x1, 0x2, 0x3, 0x4>> = Encoder.encode([1, 2, 3, 4])
  end

  test "Encode tiny list in v2" do
    assert <<0x94, 0x1, 0x2, 0x3, 0x4>> = Encoder.encode([1, 2, 3, 4], 2)
  end
end
