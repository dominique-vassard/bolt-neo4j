defmodule BoltNeo4j.Types do
  defmodule TimeWithTZ do
    defstruct [:time, :timezone_offset]
  end

  defmodule DateTimeWithOffset do
    defstruct [:naivedatetime, :timezone_offset]
  end

  defmodule Duration do
    defstruct [:months, :days, :seconds, :nanoseconds]
  end
end
