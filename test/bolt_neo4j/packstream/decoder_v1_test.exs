defmodule BoltNeo4j.Packstream.DecoderV1Test do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.EncoderV1
  alias BoltNeo4j.Packstream.DecoderV1

  describe "Decode Atoms:" do
    test "nil" do
      assert [nil] == DecoderV1.decode(<<0xC0>>, 1)
    end

    test "true" do
      assert [true] == DecoderV1.decode(<<0xC3>>, 1)
    end

    test "false" do
      assert [false] == DecoderV1.decode(<<0xC2>>, 1)
    end
  end

  describe "Decode integers:" do
    test "tiny int" do
      assert [42] = DecoderV1.decode(<<0x2A>>, 1)
    end

    test "int8" do
      assert [-42] = DecoderV1.decode(<<0xC8, 0xD6>>, 1)
    end

    test "int16" do
      assert [4_200] = DecoderV1.decode(<<0xC9, 0x10, 0x68>>, 1)
    end

    test "negative int16" do
      assert [-4_200] = DecoderV1.decode(<<0xC9, 0xEF, 0x98>>, 1)
    end

    test "int32" do
      assert [42_000] = DecoderV1.decode(<<0xCA, 0x00, 0x00, 0xA4, 0x10>>, 1)
    end

    test "negative int32" do
      assert [-42_000] = DecoderV1.decode(<<0xCA, 0xFF, 0xFF, 0x5B, 0xF0>>, 1)
    end

    test "int64" do
      assert [42_000_000_000] =
               DecoderV1.decode(<<0xCB, 0x00, 0x00, 0x00, 0x09, 0xC7, 0x65, 0x24, 0x00>>, 1)
    end

    test "negative int64" do
      assert [-42_000_000_000] =
               DecoderV1.decode(<<0xCB, 0xFF, 0xFF, 0xFF, 0xF6, 0x38, 0x9A, 0xDC, 0x00>>, 1)
    end
  end

  describe "Decode lists:" do
    test "tiny list" do
      assert [[1, 3, 4, 6]] = DecoderV1.decode(<<0x94, 0x1, 0x3, 0x4, 0x6>>, 1)
    end

    test "list8" do
      res =
        DecoderV1.decode(
          <<0xD4, 0x14, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5,
            0x6, 0x7, 0x8, 0x9, 0x0>>,
          1
        )

      assert [[1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]] = res
    end

    test "list16" do
      original = Enum.into(1..258, [])
      encoded = EncoderV1.encode_list(original, 1)
      assert [^original] = DecoderV1.decode(encoded, 1)
    end

    test "list32" do
      original = Enum.into(1..66_000, [])
      encoded = EncoderV1.encode_list(original, 1)
      assert [^original] = DecoderV1.decode(encoded, 1)
    end
  end

  describe "Decode strings:" do
    test "Empty string" do
      assert [""] = DecoderV1.decode(<<0x80>>, 1)
    end

    test "Tiny string" do
      assert ["hello"] = DecoderV1.decode(<<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>>, 1)
    end

    test "String8" do
      assert ["âme à écorchure"] =
               DecoderV1.decode(
                 <<0xD0, 0x12, 0xC3, 0xA2, 0x6D, 0x65, 0x20, 0xC3, 0xA0, 0x20, 0xC3, 0xA9, 0x63,
                   0x6F, 0x72, 0x63, 0x68, 0x75, 0x72, 0x65>>,
                 1
               )
    end

    test "String16" do
      original = String.duplicate("a", 258)
      encoded = EncoderV1.encode_string(original)
      assert [^original] = DecoderV1.decode(encoded, 1)
    end

    test "String32" do
      original = String.duplicate("a", 66_000)
      encoded = EncoderV1.encode_string(original)
      assert [^original] = DecoderV1.decode(encoded, 1)
    end
  end
end
