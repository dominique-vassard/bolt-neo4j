defmodule BoltNeo4j.Packstream.MessageTest do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.Message.{AckFailure, Init, PullAll, Run}

  describe "Init module:" do
    test "signature/0" do
      assert 0x01 = Init.signature()
    end

    test "list_data/1" do
      client_name = "MyClient/1.0"
      auth_token = %{}

      struct = %Init{client_name: client_name, auth_token: auth_token}
      assert [^client_name, ^auth_token] = Init.list_data(struct)
    end
  end

  describe "AckFailure module:" do
    test "signature/0" do
      assert 0x0E = AckFailure.signature()
    end

    test "list_data/1" do
      assert [] = AckFailure.list_data(%AckFailure{})
    end
  end

  describe "Run module:" do
    test "signature/0" do
      assert 0x10 = Run.signature()
    end

    test "list_data/1" do
      statement = "MATCH (n) WHERE uid = {uid}"
      parameters = %{uid: "1233-frer"}

      struct = %Run{statement: statement, parameters: parameters}
      assert [^statement, ^parameters] = Run.list_data(struct)
    end
  end

  describe "PullAll module:" do
    test "signature/0" do
      assert 0x3F = PullAll.signature()
    end

    test "list_data/1" do
      assert [] = PullAll.list_data(%PullAll{})
    end
  end
end
