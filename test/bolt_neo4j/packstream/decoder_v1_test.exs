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

  describe "Decode floats:" do
    test "Positive float" do
      assert [1.1] = DecoderV1.decode(<<0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>, 1)
    end

    test "Negative float" do
      assert [-1.1] =
               DecoderV1.decode(<<0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>>, 1)
    end
  end

  describe "Decode maps: " do
    test "Empty map" do
      assert [%{}] = DecoderV1.decode(<<0xA0>>, 1)
    end

    test "Tiny map" do
      assert [%{"a" => 1}] = DecoderV1.decode(<<0xA1, 0x81, 0x61, 0x1>>, 1)
    end

    test "Map8" do
      map = [
        %{
          "a" => 1,
          "b" => 1,
          "c" => 3,
          "d" => 4,
          "e" => 5,
          "f" => 6,
          "g" => 7,
          "h" => 8,
          "i" => 9,
          "j" => 0,
          "k" => 1,
          "l" => 2,
          "m" => 3,
          "n" => 4,
          "o" => 5,
          "p" => 6
        }
      ]

      assert ^map =
               DecoderV1.decode(
                 <<0xD8, 0x10, 0x81, 0x61, 0x1, 0x81, 0x62, 0x1, 0x81, 0x63, 0x3, 0x81, 0x64, 0x4,
                   0x81, 0x65, 0x5, 0x81, 0x66, 0x6, 0x81, 0x67, 0x7, 0x81, 0x68, 0x8, 0x81, 0x69,
                   0x9, 0x81, 0x6A, 0x0, 0x81, 0x6B, 0x1, 0x81, 0x6C, 0x2, 0x81, 0x6D, 0x3, 0x81,
                   0x6E, 0x4, 0x81, 0x6F, 0x5, 0x81, 0x70, 0x6>>,
                 1
               )
    end

    test "Map16" do
      original = 1..258 |> Enum.map(&{"a#{&1}", &1}) |> Map.new()
      encoded = EncoderV1.encode_map(original, 1)
      res = DecoderV1.decode(encoded, 1)
      assert res |> List.first() |> map_size() == 258
    end

    test "Map32" do
      original = 1..66_000 |> Enum.map(&{"a#{&1}", &1}) |> Map.new()
      encoded = EncoderV1.encode_map(original, 1)
      res = DecoderV1.decode(encoded, 1)
      assert res |> List.first() |> map_size() == 66_000
    end
  end
end
