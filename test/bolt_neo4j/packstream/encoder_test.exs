defmodule BoltNeo4j.Packstream.EncoderTest do
  use ExUnit.Case

  alias BoltNeo4j.Types.{DateTimeWithOffset, TimeWithTZ}
  alias BoltNeo4j.Packstream.{Encoder, EncoderHelper, Helper}
  alias BoltNeo4j.Packstream.Message.{AckFailure, DiscardAll, Init, PullAll, Reset, Run}

  defmodule TestStruct do
    defstruct [:id, :value]
  end

  test "Encode nil in v1" do
    assert <<0xC0>> = Encoder.encode(nil)
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

      assert <<_::binary>> = Encoder.encode(%DiscardAll{}, version)

      assert <<_::binary>> =
               Encoder.encode(%Init{client_name: "MyClient/1.0", auth_token: %{}}, version)

      assert <<_::binary>> = Encoder.encode(%PullAll{}, version)

      assert <<_::binary>> = Encoder.encode(%Reset{}, version)

      assert <<_::binary>> =
               Encoder.encode(%Run{statement: "RETURN 1 AS num", parameters: %{}}, version)
    end)
  end

  test "Encode in V2" do
    assert <<_::binary>> = Encoder.encode(~D[2018-07-14], 2)

    assert <<_::binary>> =
             Encoder.encode(%TimeWithTZ{time: ~T[12:45:30.250000], timezone_offset: 3600}, 2)

    assert <<_::binary>> = Encoder.encode(~T[14:45:53.34], 2)
    assert <<_::binary>> = Encoder.encode(~N[2018-04-05 12:34:00.543], 2)

    assert <<_::binary>> =
             Encoder.encode(
               %DateTimeWithOffset{
                 naivedatetime: ~N[2016-05-24 13:26:08.543],
                 timezone_offset: 7200
               },
               2
             )

    assert <<_::binary>> =
             Encoder.encode(
               Helper.datetime_with_micro(~N[2016-05-24 13:26:08.543], "Europe/Berlin"),
               2
             )
  end
end
