defmodule BoltNeo4j.Packstream.Helper do
  @available_version [1, 2]

  @doc """
  Retrieve previous version
  """
  def previous_version(version) do
    @available_version
    |> Enum.take_while(&(&1 < version))
    |> List.last()
  end

  def mod_version(version) do
    String.replace(stringify_version(version), ".", "_")
  end

  defp stringify_version(version) when is_float(version) do
    Float.to_string(version)
  end

  defp stringify_version(version) when is_integer(version) do
    Integer.to_string(version)
  end
end
