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
  def decode(<<@tiny_list_marker::4, _size::4, rest::binary>>, version) do
    [Decoder.decode(rest, version)]
  end

  def decode(<<@list8_marker, _size::8, rest::binary>>, version) do
    [Decoder.decode(rest, version)]
  end

  def decode(<<@list16_marker, _size::16, rest::binary>>, version) do
    [Decoder.decode(rest, version)]
  end

  def decode(<<@list32_marker, _size::32, rest::binary>>, version) do
    [Decoder.decode(rest, version)]
  end

  # Decode maps
  def decode(<<@tiny_map_marker::4, _nb_entries::4, rest::binary>>, version) do
    [decode_map(rest, version)]
  end

  def decode(<<@map8_marker, _nb_entries::8, rest::binary>>, version) do
    [decode_map(rest, version)]
  end

  def decode(<<@map16_marker, _nb_entries::8, rest::binary>>, version) do
    [decode_map(rest, version)]
  end

  def decode(<<@map32_marker, _nb_entries::8, rest::binary>>, version) do
    [decode_map(rest, version)]
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

  defp decode_map(data, version) do
    Decoder.decode(data, version)
    |> Enum.chunk_every(2)
    |> Enum.map(&List.to_tuple/1)
    |> Map.new()
  end
end
