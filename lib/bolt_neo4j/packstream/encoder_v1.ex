defmodule BoltNeo4j.Packstream.EncoderV1 do
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

  @tiny_list_marker 0x9
  @list8_marker 0xD4
  @list16_marker 0xD5
  @list32_marker 0xD6

  @tiny_string_marker 0x8
  @string8_marker 0xD0
  @string16_marker 0xD1
  @string32_marker 0xD2

  @doc """
  Encode atoms

  If atom is known (nil, true, false) then encode it
  otherwise, encode its string representation
  """
  def encode_atom(nil), do: <<@null_marker>>
  def encode_atom(true), do: <<@true_marker>>
  def encode_atom(false), do: <<@false_marker>>

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
    |> Enum.into(<<>>, &BoltNeo4j.Packstream.Encoder.encode(&1, version))
  end
end
