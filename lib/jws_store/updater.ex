defmodule JWKStore.Updater do
  @moduledoc false
  use GenServer
  require Logger
  alias JWKStore.Storage

  @times_to_try 5

  defmodule Config do
    @moduledoc false
    defstruct storage: nil,
              uri: nil,
              timer_ref: nil,
              retry_times: 0
  end

  def fetch(%URI{} = uri) do
    uri_as_charlist =
      uri
      |> URI.to_string()
      |> String.to_charlist()

    case :httpc.request(:get, {uri_as_charlist, []}, [], []) do
      {:ok, {{_, 200, _}, headers, body}} ->
        # https://developers.google.com/identity/sign-in/web/backend-auth#verify-the-integrity-of-the-id-token
        # "examine the Cache-Control header in the response to determine when you should retrieve them again"
        max_age =
          Enum.find_value(headers, fn
            {'cache-control', v} ->
              Regex.run(~r/max-age=(\d+)/, to_string(v), capture: :all_but_first)
              |> List.first()
              |> String.to_integer()

            _ ->
              false
          end)

        {:ok, Jason.decode!(body)["keys"], max_age}

      {:ok, {{_, status_code, _}, _, body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def perform(%URI{} = uri, storage) when is_atom(storage) or is_pid(storage) do
    case fetch(uri) do
      {:ok, jwks, max_age} ->
        :ok = Storage.update(storage, jwks)
        {:ok, max_age}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_millisec_to_next_update(updater) when is_atom(updater) or is_pid(updater) do
    GenServer.call(updater, :get_millisec_to_next_update)
  end

  def start_link({storage, %URI{} = uri, options}) when (is_atom(storage) or is_pid(storage)) and is_list(options) do
    GenServer.start(__MODULE__, %Config{storage: storage, uri: uri}, options)
  end

  @impl GenServer
  def init(%Config{} = config) do
    send(self(), :tick)
    {:ok, config}
  end

  @impl GenServer
  def handle_call(:get_millisec_to_next_update, _from, %Config{timer_ref: timer_ref} = config) do
    millisec_to_next_update =
      case Process.read_timer(timer_ref) do
        n when is_integer(n) and 0 <= n ->
          n

        _ ->
          0
      end

    {:reply, millisec_to_next_update, config}
  end

  @impl GenServer
  def handle_info(:tick, %Config{storage: storage, uri: uri, retry_times: retry_times} = config) do
    case perform(uri, storage) do
      {:ok, max_age} ->
        # It is a good manner to balance access. So, it waits additional 1-60 secs.
        waiting_millisecs = (max_age + :rand.uniform(60)) * 1000
        timer_ref = Process.send_after(self(), :tick, waiting_millisecs)

        Logger.info(fn ->
          next_tick =
            DateTime.utc_now()
            |> DateTime.add(waiting_millisecs, :millisecond)
            |> DateTime.truncate(:second)
            |> DateTime.to_iso8601()

          ["JWK updated. Next update will be at ", next_tick, "."]
        end)

        {:noreply, %{config | timer_ref: timer_ref, retry_times: 0}}

      {:error, reason} ->
        if retry_times < @times_to_try do
          waiting_millisecs = trunc(:math.pow(retry_times + 1, 2)) * 1000
          timer_ref = Process.send_after(self(), :tick, waiting_millisecs)

          Logger.warn(fn ->
            next_tick =
              DateTime.utc_now()
              |> DateTime.add(waiting_millisecs, :millisecond)
              |> DateTime.truncate(:second)
              |> DateTime.to_iso8601()

            [
              "Failed updating JWK. Retry times is ",
              retry_times,
              "Next update will be at ",
              inspect(next_tick),
              ". Reason is ",
              inspect(reason),
              "."
            ]
          end)

          {:noreply, %{config | timer_ref: timer_ref, retry_times: retry_times + 1}}
        else
          error_reason = :too_many_fetching_errors
          Logger.error(%{retry_times: retry_times, reason: error_reason})
          {:stop, error_reason, config}
        end
    end
  end
end
