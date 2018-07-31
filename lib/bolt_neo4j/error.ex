defmodule BoltNeo4j.Error do
  defexception [:message, :code, :connection_id, :function, :type]

  # def exception(message, pid, function) do
  #   %BoltNeo4j.Error{
  #     message: message_for(function, message),
  #     connection_id: get_id(pid),
  #     function: function,
  #     type: :protocol_error
  #   }
  # end

  def exception(%{"message" => message, "code" => code}, pid, function) do
    %BoltNeo4j.Error{
      message: message,
      code: code,
      connection_id: get_id(pid),
      function: function,
      type: :cypher_error
    }
  end

  def exception({:error, :closed}, pid, function) do
    %BoltNeo4j.Error{
      message: "Port #{inspect(pid)} is closed",
      connection_id: get_id(pid),
      function: function,
      type: :connection_error
    }
  end

  def exception(message, pid, function) do
    %BoltNeo4j.Error{
      message: message_for(function, message),
      connection_id: get_id(pid),
      function: function,
      type: :protocol_error
    }
  end

  defp message_for(_function, {:ignored, _}) do
    """
    The session is in a failed state and ignores further messages. You need to
    `ACK_FAILURE` or `RESET` in order to send new messages.
    """
  end

  defp message_for(function, message) do
    """
    #{function}: Unknown failure: #{inspect(message)}
    """
  end

  defp get_id({:sslsocket, {:gen_tcp, port, _tls, _unused_yet}, _pid}) do
    get_id(port)
  end

  defp get_id(port) when is_port(port) do
    case Port.info(port, :id) do
      {:id, id} -> id
      nil -> nil
    end
  end

  defp get_id(_), do: nil
end
