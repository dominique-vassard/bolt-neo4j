defmodule BoltNeo4j.Packstream.EncoderTest do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.{Encoder, EncoderHelper}
  alias BoltNeo4j.Packstream.Message.{AckFailure, Init, PullAll, Run}

  defmodule TestStruct do
    defstruct [:id, :value]
  end

  test "Encode nil in v1" do
    assert <<0xC0>> = Encoder.encode(nil)
  end

  test "Encode nil in v2" do
    assert {:error, _} = Encoder.encode(nil, 2)
  end

  test "Encode all common types" do
    Enum.each(EncoderHelper.available_versions(), fn version ->
      assert <<_::binary>> = Encoder.encode(true, version)
      assert <<_::binary>> = Encoder.encode(7, version)
      assert <<_::binary>> = Encoder.encode(7.7, version)
      assert <<_::binary>> = Encoder.encode("hello", version)
      assert <<_::binary>> = Encoder.encode([], version)
      assert <<_::binary>> = Encoder.encode([2, 4], version)
      assert <<_::binary>> = Encoder.encode(%{ok: 5}, version)
      assert <<_::binary>> = Encoder.encode({0x01, %TestStruct{id: 1, value: "hello"}}, version)

      assert <<_::binary>> = Encoder.encode(%AckFailure{}, version)

      assert <<_::binary>> =
               Encoder.encode(%Init{client_name: "MyClient/1.0", auth_token: %{}}, version)

      assert <<_::binary>> = Encoder.encode(%PullAll{}, version)

      assert <<_::binary>> =
               Encoder.encode(%Run{statement: "RETURN 1 AS num", parameters: %{}}, version)
    end)
  end
end
