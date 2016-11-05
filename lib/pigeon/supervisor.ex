defmodule Pigeon.Supervisor do
  @moduledoc """
    Supervises an APNSWorker, restarting as necessary.
  """
  use Supervisor

  def start_link, do: Supervisor.start_link(__MODULE__, :ok, name: :pigeon)

  def stop, do: :gen_server.cast(:pigeon, :stop)

  def init(:ok) do
    supervise([], strategy: :one_for_one)
  end

  def ping(pool_name) do
    :poolboy.transaction(pool_name, fn(worker) ->
      GenServer.cast(worker, :ping)
    end)
  end

  def push(pool_name, notification, on_response \\ nil) do
    case on_response do
      nil ->
        :poolboy.transaction(pool_name, fn(worker) ->
          GenServer.cast(worker, {:push, :apns, notification})
        end)
      on_response ->
        :poolboy.transaction(pool_name, fn(worker) ->
          GenServer.cast(worker, {:push, :apns, notification, on_response})
        end)
    end
  end

  def handle_cast(:stop, state), do: { :noreply, state }
end
