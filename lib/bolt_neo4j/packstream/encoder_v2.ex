defmodule BoltNeo4j.Packstream.EncoderV2 do
  alias BoltNeo4j.Packstream.Encoder

  @tiny_struct_marker 0xB

  @date_marker 0x44
  @date_struct_size 1

  # Encode DATE
  def encode_date(date, version) do
    epoch = Date.diff(date, ~D[1970-01-01])

    <<@tiny_struct_marker::4, @date_struct_size::4, @date_marker>> <>
      Encoder.encode(epoch, version)
  end
end
