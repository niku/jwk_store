defmodule JWKStore.Storage do
  @moduledoc false
  use Agent

  def update(storage, jwks) when (is_pid(storage) or is_atom(storage)) and is_list(jwks) do
    new_map = for jwk <- jwks, do: {jwk["kid"], jwk}, into: Map.new()
    Agent.update(storage, fn _ -> new_map end)
  end

  def lookup(storage, key) when (is_pid(storage) or is_atom(storage)) and is_binary(key) do
    Agent.get(storage, &Map.get(&1, key))
  end

  def start_link(options \\ []) when is_list(options) do
    Agent.start_link(&Map.new/0, options)
  end
end
