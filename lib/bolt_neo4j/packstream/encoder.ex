alias BoltNeo4j.Packstream.EncoderHelper

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

defimpl BoltNeo4j.Packstream.Encoder, for: Any do
  def encode(_, version) do
    {:error, "Type not supported in version #{version}"}
  end
end
