defmodule JWKStore do
  @moduledoc """
  Documentation for JWKStore.
  """

  use Supervisor
  alias JWKStore.{Storage, Updater}

  @storage JWKStore.Storage
  @updater JWKStore.Updater
  @spec lookup(binary) :: nil | map
  def lookup(key) when is_binary(key) do
    Storage.lookup(@storage, key)
  end

  @spec get_millisec_to_next_update :: non_neg_integer
  def get_millisec_to_next_update do
    Updater.get_millisec_to_next_update(@updater)
  end

  @spec start_link(URI.t()) :: {:error, any} | {:ok, pid}
  def start_link(%URI{} = uri) do
    Supervisor.start_link(__MODULE__, uri, name: __MODULE__)
  end

  @impl Supervisor
  def(init(%URI{} = uri)) do
    children = [
      {@storage, name: @storage},
      {@updater, {@storage, uri, name: @updater}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
