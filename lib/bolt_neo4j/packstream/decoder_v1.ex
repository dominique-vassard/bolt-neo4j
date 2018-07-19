defmodule BoltNeo4j.Packstream.DecoderV1 do
  alias BoltNeo4j.Packstream.Decoder

  @null_marker 0xC0
  @true_marker 0xC3
  @false_marker 0xC2

  @int8_marker 0xC8
  @int16_marker 0xC9
  @int32_marker 0xCA
  @int64_marker 0xCB

  @tiny_list_marker 0x9
  @list8_marker 0xD4
  @list16_marker 0xD5
  @list32_marker 0xD6

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

  def decode(<<0x0>>, _), do: []
  def decode("", _), do: []

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
end
