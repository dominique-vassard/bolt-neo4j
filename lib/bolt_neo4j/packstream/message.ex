defmodule BoltNeo4j.Packstream.Message.Init do
  @moduledoc """
  This module holds data and functions required dor INIT message
  """

  @client_name "BoltNeo4j/0.1"
  @signature 0x01

  defstruct client_name: @client_name, auth_token: {}

  @doc """
  Returns the INIT message signature
  """
  def signature do
    @signature
  end

  @doc """
  Build a list of data from Init structure
  """
  def list_data(%{client_name: client_name, auth_token: auth_token}) do
    [client_name, auth_token]
  end
end
