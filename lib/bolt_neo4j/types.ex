defmodule BoltNeo4j.Types do
  defmodule TimeWithTZ do
    defstruct [:time, :timezone_offset]
  end
end
