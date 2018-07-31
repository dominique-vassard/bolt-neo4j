alias BoltNeo4j.Packstream.EncoderHelper
alias BoltNeo4j.Packstream.Message.{AckFailure, DiscardAll, Init, PullAll, Reset, Run}

require Logger

defprotocol BoltNeo4j.Packstream.Encoder do
  @fallback_to_any true

  def encode(data, version \\ 1)
end

defimpl BoltNeo4j.Packstream.Encoder, for: Atom do
  def encode(data, version) do
    EncoderHelper.call_encode(:atom, data, version)
  end
end

defimpl BoltNeo4j.Packstream.Encoder, for: Integer do
  def encode(data, version) do
    EncoderHelper.call_encode(:integer, data, version)
  end
end

defimpl BoltNeo4j.Packstream.Encoder, for: List do
  def encode(data, version) do
    EncoderHelper.call_encode(:list, data, version)
  end
end

defimpl BoltNeo4j.Packstream.Encoder, for: BitString do
  def encode(data, version) do
    EncoderHelper.call_encode(:string, data, version)
  end
end

defimpl BoltNeo4j.Packstream.Encoder, for: Float do
  def encode(data, version) do
    EncoderHelper.call_encode(:float, data, version)
  end
end

defimpl BoltNeo4j.Packstream.Encoder, for: Map do
  def encode(data, version) do
    EncoderHelper.call_encode(:map, data, version)
  end
end

defimpl BoltNeo4j.Packstream.Encoder, for: [AckFailure, DiscardAll, Init, PullAll, Reset, Run] do
  @max_chunk_size 65_535
  @end_marker <<0x00, 0x00>>

  def encode(data, version) do
    EncoderHelper.call_encode(:struct, {@for.signature, @for.list_data(data)}, version)
    |> generate_chunks()
  end

  defp generate_chunks(data, chunks \\ [])

  defp generate_chunks(data, chunks) when byte_size(data) > @max_chunk_size do
    <<chunk::binary-@max_chunk_size, rest::binary>> = data
    generate_chunks(rest, [format_chunk(chunk) | chunks])
  end

  defp generate_chunks(<<>>, chunks) do
    [@end_marker | chunks]
    |> Enum.reverse()
    |> Enum.join()
  end

  defp generate_chunks(data, chunks) do
    generate_chunks(<<>>, [format_chunk(data) | chunks])
  end

  defp format_chunk(chunk) do
    <<byte_size(chunk)::16>> <> chunk
  end
end

defimpl BoltNeo4j.Packstream.Encoder, for: Any do
  def encode({_signature, %{__struct__: _}} = data, version) do
    EncoderHelper.call_encode(:struct, data, version)
  end

  def encode(data, _version) do
    raise BoltNeo4j.Packstream.EncodeError, item: data
  end
end
