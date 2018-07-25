defmodule BoltNeo4j.Bolt do
  alias BoltNeo4j.Logger
  alias BoltNeo4j.Packstream.Encoder
  alias BoltNeo4j.Packstream.Decoder

  alias BoltNeo4j.Packstream.Message.{Init, AckFailure}

  @recv_timeout 10_000

  @handshake_preamble <<0x60, 0x60, 0xB0, 0x17>>

  @fallback_protocol_version 1
  @min_version 1
  @max_version 2

  @moduledoc """
  This module handles the Bolt protocol specific steps (handshake, init) as well as sending and
  receiving data.

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
    version = get_protocol_version(options)

    do_handshake(transport, port, version, recv_timeout)
  end

  defp do_handshake(transport, port, version, recv_timeout) do
    # Define version list. Should be a 4 integer list
    # Example: [1, 0, 0, 0]
    versions =
      ((version..0
        |> Enum.into([])) ++ [0, 0, 0])
      |> Enum.take(4)

    Logger.log_message(
      :client,
      :handshake,
      "#{inspect(@handshake_preamble, base: :hex)} #{inspect(versions)}"
    )

    # Send handshkake
    data = @handshake_preamble <> Enum.into(versions, <<>>, fn version_ -> <<version_::32>> end)
    transport.send(port, data)

    # Logger.debug(fn ->
    #   "C: HANDSHAKE ~ #{inspect(data, base: :hex)}"
    # end)

    # Receive handshake
    case transport.recv(port, 4, recv_timeout) do
      {:ok, <<x::32>> = packet} when x <= @max_version ->
        Logger.log_message(:server, :handshake, packet)
        {:ok, version}

      {:error, _} ->
        {:error, "Couldn't handshake"}
    end
  end

  @doc """
  Initialises the connection.

  Expects a transport module (i.e. `gen_tcp`) and a `Port`. Accepts
  authorisation params in the form of {username, password}.

  ## Options

  See "Shared options" in the documentation of this module.

  ## Examples

      iex> BoltNeo4j.Bolt.init :gen_tcp, port
      {:ok, info}

      iex> BoltNeo4j.Bolt.init :gen_tcp, port, {"username", "password"}
      {:ok, info}
  """
  def init(transport, port, auth \\ {}, options \\ []) do
    map_auth = get_auth(auth)
    recv_timeout = get_recv_timeout(options)
    version = get_protocol_version(options)

    init_struct = %Init{auth_token: map_auth}
    Logger.log_message(:client, :init, init_struct)

    data = Encoder.encode(init_struct, version)

    # Logger.log_message(:client, :init, data, :hex)

    transport.send(port, data)

    recv_data = receive_data(transport, port, recv_timeout, version)
    Logger.log_message(:server, recv_data)

    case recv_data do
      {:success, data} -> {:ok, data}
      {:failure, error} -> {:error, error}
    end
  end

  @doc """
  Implementation of Bolt's ACK_FAILURE. It acknowledges a failure while keeping
  transactions alive.

  See http://boltprotocol.org/v1/#message-ack-failure

  ## Options

  See "Shared options" in the documentation of this module.
  """
  def ack_failure(transport, port, options \\ []) do
    recv_timeout = get_recv_timeout(options)
    version = get_protocol_version(options)

    Logger.log_message(:client, :ack_failure, [])

    data = Encoder.encode(%AckFailure{}, version)

    Logger.log_message(:client, :ack_failure, data, :hex)

    transport.send(port, data)

    recv_data = receive_data(transport, port, recv_timeout, version)
    Logger.log_message(:server, recv_data)

    case recv_data do
      {:success, data} -> {:ok, data}
      {:failure, error} -> {:error, error}
    end
  end

  defp receive_data(transport, port, recv_timeout, version, responses \\ [])

  defp receive_data(transport, port, recv_timeout, version, responses) do
    case transport.recv(port, 2, recv_timeout) do
      {:ok, <<0x00, 0x00>>} ->
        case length(responses) do
          1 -> List.first(responses)
          _ -> Enum.reverse(responses)
        end

      {:ok, <<chunk_size::integer-16>>} ->
        case transport.recv(port, chunk_size, recv_timeout) do
          {:ok, data} ->
            receive_data(transport, port, recv_timeout, version, [
              Decoder.decode_message(data, version) | responses
            ])

          error ->
            error
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_auth({}) do
    %{}
  end

  defp get_auth({user, pass}) do
    %{
      scheme: "basic",
      principal: user,
      credentials: pass
    }
  end

  defp get_recv_timeout(options) do
    Keyword.get(options, :recv_timeout, @recv_timeout)
  end

  defp get_protocol_version(options) do
    version =
      Keyword.get(options, :protocol_version, @fallback_protocol_version)
      |> check_version()

    case version do
      {:ok, version} -> version
      error -> error
    end
  end

  defp check_version(version) when version <= @max_version and version >= @min_version,
    do: {:ok, version}

  defp check_version(_), do: {:error, "Unsupported protocol version"}
end
