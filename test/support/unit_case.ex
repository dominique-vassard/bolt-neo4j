defmodule BoltNeo4j.UnitCase do
  use ExUnit.CaseTemplate

  def neo4j_uri do
    "bolt://neo4j:test@localhost:7687"
    |> URI.merge(System.get_env("NEO4J_TEST_URL") || "")
    |> URI.parse()
    |> Map.update!(:host, &String.to_charlist/1)
    |> Map.update!(:userinfo, fn
      nil ->
        {}

      userinfo ->
        userinfo
        |> String.split(":")
        |> List.to_tuple()
    end)
  end
end
