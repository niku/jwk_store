defmodule JWKStore do
  @moduledoc """
  Documentation for JWKStore.
  """

  alias JWKStore.{Storage, Updater}

  @storage JWKStore.Storage
  @updater JWKStore.Updater

  @spec start_link(URI.t()) :: {:error, any} | {:ok, pid}
  def start_link(%URI{} = url) do
    children = [
      {@storage, name: @storage},
      {@updater, {@storage, url, name: @updater}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end

  @spec lookup(binary) :: nil | map
  def lookup(key) when is_binary(key) do
    Storage.lookup(@storage, key)
  end

  @spec get_millisec_to_next_update :: non_neg_integer
  def get_millisec_to_next_update do
    Updater.get_millisec_to_next_update(@updater)
  end
end
