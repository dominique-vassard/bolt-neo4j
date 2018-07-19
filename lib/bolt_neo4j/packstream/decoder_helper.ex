defmodule BoltNeo4j.Packstream.DecoderHelper do
  @available_version [1, 2]

  @doc """
  Call  'decode' function on the right module depending on the given version.

  If version is nil, it's an error.

  If function returns {:error, _}, then lauch `decode` with the same data on the previous version
  """
  def call_decode(_, nil) do
    {:error, "Not implemented"}
  end

  def call_decode(data, version) do
    module =
      String.to_existing_atom("Elixir.BoltNeo4j.Packstream.DecoderV#{mod_version(version)}")

    case Kernel.apply(module, :decode, [data, version]) do
      {:error, _} -> call_decode(data, previous_version(version))
      res -> res
    end
  end

  @doc """
  Retrieve previous version
  """
  def previous_version(version) do
    @available_version
    |> Enum.take_while(&(&1 < version))
    |> List.last()
  end

  defp mod_version(version) do
    String.replace(stringify_version(version), ".", "_")
  end

  defp stringify_version(version) when is_float(version) do
    Float.to_string(version)
  end

  defp stringify_version(version) when is_integer(version) do
    Integer.to_string(version)
  end
end
