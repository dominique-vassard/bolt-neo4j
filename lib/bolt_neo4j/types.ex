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

  defmodule Point do
    @srid_cartesian 7203
    @srid_cartesian_3d 9157
    @srid_wgs_84 4326
    @srid_wgs_84_3d 4979

    defstruct [:crs, :srid, :x, :y, :z, :longitude, :latitude, :height]

    defguardp is_valid_coords(x, y) when is_number(x) and is_number(y)
    defguardp is_valid_coords(x, y, z) when is_number(x) and is_number(y) and is_number(z)

    def create(:cartesian, x, y) do
      create(@srid_cartesian, x, y)
    end

    def create(:wgs_84, longitude, latitude) do
      create(@srid_wgs_84, longitude, latitude)
    end

    def create(@srid_cartesian, x, y) when is_valid_coords(x, y) do
      %Point{
        crs: crs(@srid_cartesian),
        srid: @srid_cartesian,
        x: format_coord(x),
        y: format_coord(y)
      }
    end

    def create(@srid_wgs_84, longitude, latitude) when is_valid_coords(longitude, latitude) do
      %Point{
        crs: crs(@srid_wgs_84),
        srid: @srid_wgs_84,
        x: format_coord(longitude),
        y: format_coord(latitude),
        longitude: format_coord(longitude),
        latitude: format_coord(latitude)
      }
    end

    def create(:cartesian, x, y, z) do
      create(@srid_cartesian_3d, x, y, z)
    end

    def create(:wgs_84, longitude, latitude, height) do
      create(@srid_wgs_84_3d, longitude, latitude, height)
    end

    def create(@srid_cartesian_3d, x, y, z) when is_valid_coords(x, y, z) do
      %Point{
        crs: crs(@srid_cartesian_3d),
        srid: @srid_cartesian_3d,
        x: format_coord(x),
        y: format_coord(y),
        z: format_coord(z)
      }
    end

    def create(@srid_wgs_84_3d, longitude, latitude, height)
        when is_valid_coords(longitude, latitude, height) do
      %Point{
        crs: crs(@srid_wgs_84_3d),
        srid: @srid_wgs_84_3d,
        x: format_coord(longitude),
        y: format_coord(latitude),
        z: format_coord(height),
        longitude: format_coord(longitude),
        latitude: format_coord(latitude),
        height: format_coord(height)
      }
    end

    def crs(@srid_cartesian), do: "cartesian"
    def crs(@srid_cartesian_3d), do: "cartesian-3d"
    def crs(@srid_wgs_84), do: "wgs-84"
    def crs(@srid_wgs_84_3d), do: "wgs-84-3d"

    defp format_coord(coord) when is_integer(coord), do: coord / 1
    defp format_coord(coord), do: coord
  end
end
