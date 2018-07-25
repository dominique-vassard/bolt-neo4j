# defmodule BoltNeo4j.Packstream.Message do
#   @max_chunk_size 65_535

#   def generate_chunks(message_data) when byte_size(message_data) > @max_chunk_size do

#   end
# end

defmodule BoltNeo4j.Packstream.Message.Init do
  # @client_name "BoltNeo4j/0.1"
  @client_name "Boltex/0.4.1"
  @signature 0x01

  defstruct client_name: @client_name, auth_token: {}

  def signature do
    @signature
  end

  def list_data(%{client_name: client_name, auth_token: auth_token}) do
    [client_name, auth_token]
  end
end
