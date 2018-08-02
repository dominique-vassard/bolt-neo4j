defmodule BoltNeo4j.Packstream.Helper do
  @doc """
  Retrieve previous version
  """
  def previous_version(version, available_versions) do
    available_versions
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

  @doc """
  Convert NaiveDateTime and timezone into a Calendar.DateTime
  Without losing micorsecond data!
  """
  def datetime_with_micro(%NaiveDateTime{} = naive_dt, timezone) do
    erl_date =
      {{naive_dt.year, naive_dt.month, naive_dt.day},
       {naive_dt.hour, naive_dt.minute, naive_dt.second}}

    micros = naive_dt.microsecond

    {:ok, dt} = Calendar.DateTime.from_erl(erl_date, timezone, micros)
    dt
  end
end
