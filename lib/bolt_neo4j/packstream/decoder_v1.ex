defmodule BoltNeo4j.Packstream.DecoderV1 do
  alias BoltNeo4j.Packstream.Decoder

  @null_marker 0xC0
  @true_marker 0xC3
  @false_marker 0xC2

  @int8_marker 0xC8
  @int16_marker 0xC9
  @int32_marker 0xCA
  @int64_marker 0xCB

  @float_marker 0xC1

  @tiny_list_marker 0x9
  @list8_marker 0xD4
  @list16_marker 0xD5
  @list32_marker 0xD6

  @tiny_string_marker 0x8
  @string8_marker 0xD0
  @string16_marker 0xD1
  @string32_marker 0xD2

  @tiny_map_marker 0xA
  @map8_marker 0xD8
  @map16_marker 0xD9
  @map32_marker 0xDA

  @tiny_struct_marker 0xB
  @struct8_marker 0xDC
  @struct16_marker 0xDD

  def decode(<<0x0>>, _), do: []
  def decode("", _), do: []

  @doc """
  Decode atoms
  """
  def decode(<<@null_marker, rest::binary>>, version) do
    [nil | Decoder.decode(rest, version)]
  end

  def decode(<<@true_marker, rest::binary>>, version) do
    [true | Decoder.decode(rest, version)]
  end

  def decode(<<@false_marker, rest::binary>>, version) do
    [false | Decoder.decode(rest, version)]
  end

  def decode(<<@tiny_string_marker::4, str_length::4, data::binary>>, version) do
    decode_string(data, str_length, version)
  end

  def decode(<<@string8_marker, str_length::8, data::binary>>, version) do
    decode_string(data, str_length, version)
  end

  def decode(<<@string16_marker, str_length::16, data::binary>>, version) do
    decode_string(data, str_length, version)
  end

  def decode(<<@string32_marker, str_length::32, data::binary>>, version) do
    decode_string(data, str_length, version)
  end

  # Decode floats
  def decode(<<@float_marker, number::float, rest::binary>>, version) do
    [number | Decoder.decode(rest, version)]
  end

  # Decode lists
  def decode(<<@tiny_list_marker::4, nb_items::4, rest::binary>>, version) do
    decode_list(rest, nb_items, version)
  end

  def decode(<<@list8_marker, nb_items::8, rest::binary>>, version) do
    decode_list(rest, nb_items, version)
  end

  def decode(<<@list16_marker, nb_items::16, rest::binary>>, version) do
    decode_list(rest, nb_items, version)
  end

  def decode(<<@list32_marker, nb_items::32, rest::binary>>, version) do
    decode_list(rest, nb_items, version)
  end

  # Decode maps
  def decode(<<@tiny_map_marker::4, nb_entries::4, rest::binary>>, version) do
    decode_map(rest, nb_entries, version)
  end

  def decode(<<@map8_marker, nb_entries::8, rest::binary>>, version) do
    decode_map(rest, nb_entries, version)
  end

  def decode(<<@map16_marker, nb_entries::16, rest::binary>>, version) do
    decode_map(rest, nb_entries, version)
  end

  def decode(<<@map32_marker, nb_entries::32, rest::binary>>, version) do
    decode_map(rest, nb_entries, version)
  end

  # Decode structs
  def decode(<<@tiny_struct_marker::4, struct_size::4, signature::8, struct::binary>>, version) do
    decode_struct(struct, signature, struct_size, version)
  end

  def decode(<<@struct8_marker, struct_size::8, signature::8, struct::binary>>, version) do
    decode_struct(struct, signature, struct_size, version)
  end

  def decode(<<@struct16_marker, struct_size::16, signature::8, struct::binary>>, version) do
    decode_struct(struct, signature, struct_size, version)
  end

  # Decode integers
  def decode(<<@int8_marker, int::signed-integer, rest::binary>>, version) do
    [int | Decoder.decode(rest, version)]
  end

  def decode(<<@int16_marker, int::signed-integer-16, rest::binary>>, version) do
    [int | Decoder.decode(rest, version)]
  end

  def decode(<<@int32_marker, int::signed-integer-32, rest::binary>>, version) do
    [int | Decoder.decode(rest, version)]
  end

  def decode(<<@int64_marker, int::signed-integer-64, rest::binary>>, version) do
    [int | Decoder.decode(rest, version)]
  end

  def decode(<<int::signed-integer, rest::binary>>, version) do
    [int | Decoder.decode(rest, version)]
  end

  defp decode_string(data, str_length, version) do
    <<str::binary-size(str_length), rest::binary>> = data
    [str | Decoder.decode(rest, version)]
  end

  defp decode_list(data, nb_items, version) do
    {new, old} =
      Decoder.decode(data, version)
      |> Enum.split(nb_items)

    [new | old]
  end

  defp decode_map(data, nb_entries, version) do
    {new, old} =
      Decoder.decode(data, version)
      |> Enum.split(2 * nb_entries)

    [new |> to_map | old]
  end

  defp to_map(data) do
    data
    |> Enum.chunk_every(2)
    |> Enum.map(&List.to_tuple/1)
    |> Map.new()
  end

  defp decode_struct(data, signature, struct_size, version) do
    {new, old} =
      data
      |> Decoder.decode(version)
      |> Enum.split(struct_size)

    [[sig: signature, fields: new] | old]
  end
end
