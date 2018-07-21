defmodule BoltNeo4j.Packstream.EncoderV1Test do
  use ExUnit.Case

  defmodule TestStruct do
    defstruct [:id, :value]
  end

  alias BoltNeo4j.Packstream.EncoderV1

  describe "Encode Atoms:" do
    test "nil" do
      assert <<0xC0>> = EncoderV1.encode_atom(nil)
    end

    test "true" do
      assert <<0xC3>> = EncoderV1.encode_atom(true)
    end

    test "false" do
      assert <<0xC2>> = EncoderV1.encode_atom(false)
    end
  end

  describe "Encode integers:" do
    test "tiny int" do
      assert <<0x2A>> = EncoderV1.encode_integer(42)
    end

    test "int8" do
      assert <<0xC8, 0xD6>> = EncoderV1.encode_integer(-42)
    end

    test "int16" do
      assert <<0xC9, 0x10, 0x68>> = EncoderV1.encode_integer(4200)
    end

    test "negative int16" do
      assert <<0xC9, 0xEF, 0x98>> = EncoderV1.encode_integer(-4200)
    end

    test "int32" do
      assert <<0xCA, 0x00, 0x00, 0xA4, 0x10>> = EncoderV1.encode_integer(42_000)
    end

    test "negative int32" do
      assert <<0xCA, 0xFF, 0xFF, 0x5B, 0xF0>> = EncoderV1.encode_integer(-42_000)
    end

    test "int64" do
      assert <<0xCB, 0x00, 0x00, 0x00, 0x09, 0xC7, 0x65, 0x24, 0x00>> =
               EncoderV1.encode_integer(42_000_000_000)
    end

    test "negative int64" do
      assert <<0xCB, 0xFF, 0xFF, 0xFF, 0xF6, 0x38, 0x9A, 0xDC, 0x00>> =
               EncoderV1.encode_integer(-42_000_000_000)
    end

    test "Out of range low" do
      assert {:error, _} = EncoderV1.encode_integer(-9_223_372_036_854_775_809)
    end

    test "Out of range high" do
      assert {:error, _} = EncoderV1.encode_integer(9_223_372_036_854_775_809)
    end
  end

  describe "Encode lists: " do
    test "empty list" do
      assert <<0x90>> = EncoderV1.encode_list([], 2)
    end

    test "Tiny list" do
      assert <<0x94, 0x1, 0x3, 0x4, 0x6>> = EncoderV1.encode_list([1, 3, 4, 6], 1)
    end

    test "List8" do
      res = EncoderV1.encode_list([1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0], 1)

      assert <<0xD4, 0x14, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0x0, 0x1, 0x2, 0x3, 0x4,
               0x5, 0x6, 0x7, 0x8, 0x9, 0x0>> = res
    end

    test "list16" do
      res = EncoderV1.encode_list(Enum.into(1..258, []), 1)
      assert <<0xD5, 0x1, 0x2, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, _::binary>> = res
    end

    test "list32" do
      res = EncoderV1.encode_list(Enum.into(1..66_000, []), 1)

      assert <<0xD6, 0x0, 0x1, 0x1, 0xD0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB,
               0xC, _::binary>> = res
    end

    test "String list" do
      assert <<0x92, 0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x85, 0x77, 0x6F, 0x72, 0x6C, 0x64>> =
               EncoderV1.encode_list(["hello", "world"], 1)
    end

    test "Heterogeneous list" do
      assert <<0x93, 0x1, 0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0x5>> =
               EncoderV1.encode_list([1, "hello", 5], 1)
    end
  end

  describe "Encode strings:" do
    test "Empty string" do
      assert <<0x80>> = EncoderV1.encode_string("")
    end

    test "Tiny string" do
      assert <<0x85, 0x68, 0x65, 0x6C, 0x6C, 0x6F>> = EncoderV1.encode_string("hello")
    end

    test "String8" do
      assert <<0xD0, 0x12, 0xC3, 0xA2, 0x6D, 0x65, 0x20, 0xC3, 0xA0, 0x20, 0xC3, 0xA9, 0x63, 0x6F,
               0x72, 0x63, 0x68, 0x75, 0x72, 0x65>> = EncoderV1.encode_string("âme à écorchure")
    end

    test "String16" do
      assert <<0xD1, 0x1, 0x2, _::binary-258>> =
               EncoderV1.encode_string(String.duplicate("a", 258))
    end

    test "String32" do
      assert <<0xD2, 0x0, 0x1, 0x1, 0xD0, _::binary-66_000>> =
               EncoderV1.encode_string(String.duplicate("a", 66_000))
    end
  end

  describe "Encode floats:" do
    test "Positive float" do
      assert <<0xC1, 0x3F, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>> =
               EncoderV1.encode_float(1.1)
    end

    test "Negative float" do
      assert <<0xC1, 0xBF, 0xF1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9A>> =
               EncoderV1.encode_float(-1.1)
    end
  end

  describe "Encode maps:" do
    test "Empty map" do
      assert <<0xA0>> = EncoderV1.encode_map(%{}, 1)
    end

    test "Tiny map" do
      assert <<0xA1, 0x81, 0x61, 0x1>> = EncoderV1.encode_map(%{a: 1}, 1)
    end

    test "Map8" do
      map = %{
        a: 1,
        b: 1,
        c: 3,
        d: 4,
        e: 5,
        f: 6,
        g: 7,
        h: 8,
        i: 9,
        j: 0,
        k: 1,
        l: 2,
        m: 3,
        n: 4,
        o: 5,
        p: 6
      }

      res = EncoderV1.encode_map(map, 1)

      assert <<0xD8, 0x10, 0x81, 0x61, 0x1, 0x81, 0x62, 0x1, 0x81, 0x63, 0x3, 0x81, 0x64, 0x4,
               0x81, 0x65, 0x5, 0x81, 0x66, 0x6, 0x81, 0x67, 0x7, 0x81, 0x68, 0x8, 0x81, 0x69,
               0x9, 0x81, 0x6A, 0x0, 0x81, 0x6B, 0x1, 0x81, 0x6C, 0x2, 0x81, 0x6D, 0x3, 0x81,
               0x6E, 0x4, 0x81, 0x6F, 0x5, 0x81, 0x70, 0x6>> = res
    end

    test "Map16" do
      map = 1..258 |> Enum.map(&{"a#{&1}", &1}) |> Map.new()

      assert <<0xD9, 0x2, 0x84, _::binary>> = EncoderV1.encode_map(map, 1)
    end

    test "Map32" do
      map = 1..66_000 |> Enum.map(&{"a#{&1}", &1}) |> Map.new()

      assert <<0xDA, 0xD0, 0x85, _::binary>> = EncoderV1.encode_map(map, 1)
    end
  end

  describe "Encode structures:" do
    test "Tiny structure with signature 0x01" do
      assert <<0xB3, 0x1, 0xA2, 0x82, 0x69, 0x64, 0x1, 0x85, 0x76, 0x61, 0x6C, 0x75, 0x65, 0x85,
               0x68, 0x65, 0x6C, 0x6C,
               0x6F>> = EncoderV1.encode_struct(%TestStruct{id: 1, value: "hello"}, 0x01, 1)
    end
  end
end
