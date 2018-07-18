defmodule BoltNeo4j.Bolt do
  require Logger

  @recv_timeout 10_000

  @handshake_preamble <<0x60, 0x60, 0xB0, 0x17>>

  @fallback_protocol_version 1
  @min_version 1
  @max_version 2

  @moduledoc """
  This module handles the Bolt protocol specific steps (handshake, init) as well
  as sending and receiving data.

  It abstracts transportation, expecing the transport layer to define
  send/2 and recv/3 analogous to :gen_tcp.

  ## Shared options

  Functions that allow for options accept these default options:

    * `recv_timeout`: The timeout for receiving a response from the Neo4J
      server (default: #{@recv_timeout})
    * `protocol_version`: The protocol version to use (default: #{@fallback_protocol_version})
  """

  @doc """
  Handshake between client and server

  ## Options

  See "Shared options" in the documentation of this module.
  """
  def handshake(transport, port, options \\ []) do
    recv_timeout = get_recv_timeout(options)

    case get_protocol_version(options) do
      {:ok, version} -> do_handshake(transport, port, version, recv_timeout)
      error -> error
    end
  end

  defp do_handshake(transport, port, version, recv_timeout) do
    # Define version list. Should be a 4 integer list
    # Example: [1, 0, 0, 0]
    versions =
      ((version..0
        |> Enum.into([])) ++ [0, 0, 0])
      |> Enum.take(4)
      |> Enum.into(<<>>, fn version_ -> <<version_::32>> end)

    # Send handshkake
    data = @handshake_preamble <> versions
    transport.send(port, data)

    Logger.debug(fn ->
      "C: HANDSHAKE ~ #{inspect(data, base: :hex)}"
    end)

    # Receive handshake
    case transport.recv(port, 4, recv_timeout) do
      {:ok, <<x::32>> = packet} when x <= @max_version ->
        Logger.debug(fn -> "S: HANDSHAKE ~ #{inspect(packet, base: :hex)}" end)
        {:ok, version}

      {:error, _} ->
        Logger.debug(fn -> "Couldn't handshake" end)
        {:error, "Couldn't handshake"}
    end
  end

  defp get_recv_timeout(options) do
    Keyword.get(options, :recv_timeout, @recv_timeout)
  end

  defp get_protocol_version(options) do
    Keyword.get(options, :protocol_version, @fallback_protocol_version)
    |> check_version()
  end

  defp check_version(version) when version <= @max_version and version >= @min_version,
    do: {:ok, version}

  defp check_version(_), do: {:error, "Unsupported protocol version"}
end
