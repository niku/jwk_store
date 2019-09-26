defmodule JWKStoreTest do
  use ExUnit.Case
  doctest JWKStore

  test "greets the world" do
    assert JWKStore.hello() == :world
  end
end
