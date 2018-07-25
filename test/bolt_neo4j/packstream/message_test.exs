defmodule BoltNeo4j.Packstream.MessageTest do
  use ExUnit.Case

  alias BoltNeo4j.Packstream.Message.{Init}

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
end
