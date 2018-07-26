defmodule BoltNeo4j.Packstream.Decoder do
  alias BoltNeo4j.Packstream.Helper

  @available_versions [1, 2]

  @doc """
  Retrieves availble encoder version numbers
  """
  def available_versions() do
    @available_versions
  end

  @doc """
  Call  'decode' function on the right module depending on the given version.

  If version is nil, it's an error.

  If function returns {:error, _}, then lauch `decode` with the same data on the previous version
  """
  def decode(data, version \\ 1) do
    do_decode(data, version)
  end

  defp do_decode(data, version) when version in @available_versions do
    do_decode(data, version, version)
  end

  defp do_decode(_, _) do
    {:error, "Unsupported decoder version"}
  end

  defp do_decode(_, _, nil) do
    {:error, "Not implemented"}
  end

  defp do_decode(data, original_version, used_version) do
    module =
      String.to_existing_atom(
        "Elixir.BoltNeo4j.Packstream.DecoderV#{Helper.mod_version(used_version)}"
      )

    case Kernel.apply(module, :decode, [data, original_version]) do
      {:error, _} ->
        do_decode(
          data,
          original_version,
          Helper.previous_version(used_version, @available_versions)
        )

      res ->
        res
    end
  end

  @success_signature 0x70
  @failure_signature 0x7F
  @record_signature 0x71
  @ignored_signature 0x7E
  @tiny_struct_marker 0xB

  @doc """
  Decode SUCCESS message
  """
  def decode_message(<<@tiny_struct_marker::4, _::4, @success_signature, data::binary>>, version) do
    {:success, List.first(decode(data, version))}
  end

  @doc """
  Decode FAILURE message
  """
  def decode_message(<<@tiny_struct_marker::4, _::4, @failure_signature, data::binary>>, version) do
    {:failure, List.first(decode(data, version))}
  end

  @doc """
  Decode RECORD message
  """
  def decode_message(<<@tiny_struct_marker::4, _::4, @record_signature, data::binary>>, version) do
    {:record, List.first(decode(data, version))}
  end

  @doc """
  Decode IGNORED message
  """
  def decode_message(<<@tiny_struct_marker::4, _::4, @ignored_signature, data::binary>>, version) do
    {:ignored, List.first(decode(data, version))}
  end
end
