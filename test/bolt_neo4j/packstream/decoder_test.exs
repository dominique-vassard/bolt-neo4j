defmodule BoltNeo4j.Packstream.DecoderTest do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.Decoder

  defmodule TestStruct do
    defstruct [:id, :value]
  end

  test "Decode common types" do
    Enum.each(Decoder.available_versions(), fn version ->
      assert [true] == Decoder.decode(<<0xC3>>, version)
      assert [42] = Decoder.decode(<<0x2A>>, version)

      assert [7.7] =
               Decoder.decode(<<0xC1, 0x40, 0x1E, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD>>, version)

      assert ["hello"] = Decoder.decode(<<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>, version)
      assert [[]] = Decoder.decode(<<0x90>>, version)
      assert [[2, 4]] = Decoder.decode(<<0x92, 0x2, 0x4>>, version)
      assert [%{"ok" => 5}] = Decoder.decode(<<0xA1, 0x82, 0x6F, 0x6B, 0x5>>, version)

      assert [[sig: 1, fields: [%{"id" => 1, "value" => "hello"}]]] =
               Decoder.decode(
                 <<0xB3, 0x1, 0xA2, 0x82, 0x69, 0x64, 0x1, 0x85, 0x76, 0x61, 0x6C, 0x75, 0x65,
                   0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>,
                 version
               )

      assert {:success, %{"server" => "Neo4j/3.4.1"}} =
               Decoder.decode_message(
                 <<0xB1, 0x70, 0xA1, 0x86, 0x73, 0x65, 0x72, 0x76, 0x65, 0x72, 0x8B, 0x4E, 0x65,
                   0x6F, 0x34, 0x6A, 0x2F, 0x33, 0x2E, 0x34, 0x2E, 0x31>>,
                 version
               )
    end)
  end
end
