defmodule BoltNeo4j.Packstream.Message do
  @callback signature() :: number()
  @callback list_data(struct()) :: [term]
end

defmodule BoltNeo4j.Packstream.Message.Init do
  @moduledoc """
  This module holds data and functions required dor INIT message
  """

  @behaviour BoltNeo4j.Packstream.Message

  @client_name "BoltNeo4j/0.1"
  @signature 0x01

  defstruct client_name: @client_name, auth_token: {}

  @doc """
  Returns the INIT message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from Init structure
  """
  def list_data(%{client_name: client_name, auth_token: auth_token}) do
    [client_name, auth_token]
  end
end

defmodule BoltNeo4j.Packstream.Message.AckFailure do
  @moduledoc """
  This module holds data and functions required dor ACK_FAILURE message
  """

  @behaviour BoltNeo4j.Packstream.Message

  @signature 0x0E

  defstruct []

  @doc """
  Returns the ACK_FAILURE message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from AckFailure structure
  """
  def list_data(_) do
    []
  end
end

defmodule BoltNeo4j.Packstream.Message.Run do
  @moduledoc """
  This module holds data and functions required for RUN message
  """

  @behaviour BoltNeo4j.Packstream.Message

  @signature 0x10

  defstruct [:statement, :parameters]

  @doc """
  Returns the RUN message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from Run structure
  """
  def list_data(%{statement: statement, parameters: parameters}) do
    [statement, parameters]
  end
end

defmodule BoltNeo4j.Packstream.Message.PullAll do
  @moduledoc """
  This module holds data and functions required for PULL_ALL message
  """

  @behaviour BoltNeo4j.Packstream.Message

  @signature 0x3F

  defstruct []

  @doc """
  Returns the PULL_ALL message signature
  """
  def signature() do
    @signature
  end

  @doc """
  Build a list of data from PullAll structure
  """
  def list_data(_) do
    []
  end
end
