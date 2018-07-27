defmodule BoltNeo4j.Packstream.EncoderV1 do
  alias BoltNeo4j.Packstream.Encoder

  @null_marker 0xC0
  @true_marker 0xC3
  @false_marker 0xC2

  @int8_marker 0xC8
  @int16_marker 0xC9
  @int32_marker 0xCA
  @int64_marker 0xCB

  @int -16..127
  @int8 -127..-17
  @int16_low -32_768..-129
  @int16_high 128..32_767
  @int32_low -2_147_483_648..-32_769
  @int32_high 32_768..2_147_483_647
  @int64_low -9_223_372_036_854_775_808..-2_147_483_649
  @int64_high 2_147_483_648..9_223_372_036_854_775_807

  @float_marker 0xC1

  @tiny_string_marker 0x8
  @string8_marker 0xD0
  @string16_marker 0xD1
  @string32_marker 0xD2

  @tiny_list_marker 0x9
  @list8_marker 0xD4
  @list16_marker 0xD5
  @list32_marker 0xD6

  @tiny_map_marker 0xA
  @map8_marker 0xD8
  @map16_marker 0xD9
  @map32_marker 0xDA

  @tiny_struct_marker 0xB
  @struct8_marker 0xDC
  @struct16_marker 0xDD

  @doc """
  Encode atoms

  If atom is known (nil, true, false) then encode it
  otherwise, encode its string representation
  """
  def encode_atom(nil), do: <<@null_marker>>
  def encode_atom(true), do: <<@true_marker>>
  def encode_atom(false), do: <<@false_marker>>
  def encode_atom(other), do: other |> Atom.to_string() |> encode_string()

  def encode_string(str) when byte_size(str) < 16 do
    <<@tiny_string_marker::4, byte_size(str)::4, (str <> <<>>)>>
  end

  def encode_string(str) when byte_size(str) < 256 do
    <<@string8_marker, byte_size(str)::8, (str <> <<>>)>>
  end

  def encode_string(str) when byte_size(str) < 65_536 do
    <<@string16_marker, byte_size(str)::16, (str <> <<>>)>>
  end

  def encode_string(str) when byte_size(str) < 4_294_967_295 do
    <<@string32_marker, byte_size(str)::32, (str <> <<>>)>>
  end

  def encode_string(_) do
    {:error, "String too long"}
  end

  # Float encoding
  def encode_float(number) do
    <<@float_marker, number::float>>
  end

  # List encoding
  def encode_list(list, version) when length(list) < 16 do
    <<@tiny_list_marker::4, length(list)::4>> <> encode_list_data(list, version)
  end

  def encode_list(list, version) when length(list) < 256 do
    <<@list8_marker, length(list)::8, encode_list_data(list, version)::binary>>
  end

  def encode_list(list, version) when length(list) < 65_536 do
    <<@list16_marker, length(list)::16, encode_list_data(list, version)::binary>>
  end

  def encode_list(list, version) when length(list) < 4_294_967_295 do
    <<@list32_marker, length(list)::32, encode_list_data(list, version)::binary>>
  end

  def encode_list(_, _) do
    {:error, "List too long"}
  end

  # Map encoding
  def encode_map(map, version) when map_size(map) < 16 do
    <<@tiny_map_marker::4, map_size(map)::4>> <> encode_map_data(map, version)
  end

  def encode_map(map, version) when map_size(map) < 256 do
    <<@map8_marker, map_size(map)::8>> <> encode_map_data(map, version)
  end

  def encode_map(map, version) when map_size(map) < 65_536 do
    <<@map16_marker, map_size(map)::16>> <> encode_map_data(map, version)
  end

  def encode_map(map, version) when map_size(map) < 4_294_967_295 do
    <<@map32_marker, map_size(map)::32>> <> encode_map_data(map, version)
  end

  # Structure encoding
  def encode_struct(struct, signature, version) when is_map(struct) and map_size(struct) < 16 do
    <<@tiny_struct_marker::4, map_size(struct)::4, signature>> <>
      encode_map(Map.from_struct(struct), version)
  end

  def encode_struct(struct, signature, version) when is_map(struct) and map_size(struct) < 256 do
    <<@struct8_marker, map_size(struct)::8, signature>> <>
      encode_map(Map.from_struct(struct), version)
  end

  def encode_struct(struct, signature, version)
      when is_map(struct) and map_size(struct) < 65_536 do
    <<@struct16_marker, map_size(struct)::16, signature>> <>
      encode_map(Map.from_struct(struct), version)
  end

  def encode_struct(list, signature, version) when is_list(list) and length(list) < 16 do
    <<@tiny_struct_marker::4, length(list)::4, signature>> <>
      (list |> Enum.map_join("", &Encoder.encode(&1, version)))
  end

  def encode_struct(list, signature, version) when is_list(list) and length(list) < 256 do
    <<@struct8_marker, length(list)::8, signature>> <> encode_struct_list(list, version)
  end

  def encode_struct(list, signature, version) when is_list(list) and length(list) < 65_535 do
    <<@struct16_marker, length(list)::16, signature>> <> encode_struct_list(list, version)
  end

  def encode_struct(_, _, _) do
    {:error, "Struct too big"}
  end

  # Integer encoding
  def encode_integer(int) when int in @int do
    <<int>>
  end

  def encode_integer(int) when int in @int8 do
    <<@int8_marker, int::8>>
  end

  def encode_integer(int) when int in @int16_low or int in @int16_high do
    <<@int16_marker, int::16>>
  end

  def encode_integer(int) when int in @int32_low or int in @int32_high do
    <<@int32_marker, int::32>>
  end

  def encode_integer(int) when int in @int64_low or int in @int64_high do
    <<@int64_marker, int::64>>
  end

  def encode_integer(_) do
    {:error, "Integer out of range"}
  end

  defp encode_list_data(data, version) do
    data
    |> Enum.into(<<>>, &Encoder.encode(&1, version))
  end

  defp encode_map_data(data, version) do
    data
    |> Enum.map_join(fn {k, v} -> Encoder.encode(k, version) <> Encoder.encode(v, version) end)
  end

  defp encode_struct_list(data, version) do
    data
    |> Enum.map_join("", &Encoder.encode(&1, version))
  end
end
