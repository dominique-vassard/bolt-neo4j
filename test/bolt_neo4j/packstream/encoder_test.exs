defmodule BoltNeo4j.Packstream.EncoderTest do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.Encoder

  test "Encode nil in v1" do
    assert <<0xC0>> = Encoder.encode(nil)
  end

  test "Encode nil in v2" do
    assert <<0xC0>> = Encoder.encode(nil)
  end
end
