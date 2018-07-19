defmodule BoltNeo4j.Packstream.Decoder do
  alias BoltNeo4j.Packstream.Helper

  def decode(data, version \\ 1) do
    do_decode(data, version)
  end

  defp do_decode(_, nil) do
    {:error, "Not implemented"}
  end

  defp do_decode(data, version) do
    module =
      String.to_existing_atom(
        "Elixir.BoltNeo4j.Packstream.DecoderV#{Helper.mod_version(version)}"
      )

    case Kernel.apply(module, :decode, [data, version]) do
      {:error, _} -> do_decode(data, Helper.previous_version(version))
      res -> res
    end
  end
end
