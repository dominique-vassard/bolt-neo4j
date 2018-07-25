defmodule BoltNeo4j.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias BoltNeo4j.Logger

  test "Log from formed message" do
    assert capture_log(fn -> Logger.log_message(:client, {:success, %{data: "ok"}}) end) =~
             "C: SUCCESS ~ %{data: \"ok\"}"
  end

  test "Log from non-formed message" do
    assert capture_log(fn -> Logger.log_message(:client, :success, %{data: "ok"}) end) =~
             "C: SUCCESS ~ %{data: \"ok\"}"
  end

  test "Log hex data" do
    assert capture_log(fn -> Logger.log_message(:client, :success, <<0x01, 0xAF>>, :hex) end) =~
             "C: SUCCESS ~ <<0x1, 0xAF>>"
  end
end
