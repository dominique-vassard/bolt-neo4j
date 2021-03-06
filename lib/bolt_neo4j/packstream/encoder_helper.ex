defmodule BoltNeo4j.Packstream.EncoderHelper do
  alias BoltNeo4j.Packstream.Helper

  @available_versions [1, 2]
  @types_requiring_version [
    :list,
    :map,
    :duration,
    :date,
    :local_time,
    :time_with_tz,
    :local_datetime,
    :datetime_with_tz,
    :datetime_with_offset,
    :point
  ]

  @doc """
  Retrieves availble encoder version numbers
  """
  def available_versions() do
    @available_versions
  end

  @doc """
  Call the right 'encode' function depending on the given version.

  If version is nil, it's an error.

  If function does not exists, search for an implementation in previous versions
  """

  def call_encode(data_type, data, version) when not (version in @available_versions) do
    if version > List.last(@available_versions) do
      call_encode(data_type, data, version, List.last(@available_versions))
    else
      call_encode(data_type, data, nil)
    end
  end

  def call_encode(data_type, data, version) when version in @available_versions do
    call_encode(data_type, data, version, version)
  end

  def call_encode(_, _, _) do
    {:error, "Unsupported encoder version"}
  end

  def call_encode(_, _, _, nil) do
    {:error, "Not implemented"}
  end

  def call_encode(data_type, data, original_version, used_version) do
    module =
      String.to_existing_atom(
        "Elixir.BoltNeo4j.Packstream.EncoderV#{Helper.mod_version(used_version)}"
      )

    func_atom = "encode_#{data_type}" |> String.to_atom()

    if Keyword.has_key?(module.__info__(:functions), func_atom) do
      do_call(data_type, module, func_atom, data, original_version)
    else
      call_encode(
        data_type,
        data,
        original_version,
        Helper.previous_version(used_version, @available_versions)
      )
    end
  end

  defp do_call(data_type, module, func_atom, data, version)
       when data_type in @types_requiring_version do
    Kernel.apply(module, func_atom, [data, version])
  end

  defp do_call(data_type, module, func_atom, {signature, data}, version)
       when data_type in [:struct] do
    Kernel.apply(module, func_atom, [data, signature, version])
  end

  defp do_call(_, module, func_atom, data, _) do
    Kernel.apply(module, func_atom, [data])
  end
end
