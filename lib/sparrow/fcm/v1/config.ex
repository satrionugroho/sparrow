defmodule Sparrow.FCM.V1.Config do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_cast({:put, name, config}, state) do
    {:noreply, Map.put(state, name, config)}
  end

  @impl true
  def handle_call({:get, name}, _from, state) do
    {:reply, Map.get(state, name), state}
  end

  def put_config(name, config) do
    GenServer.cast(__MODULE__, {:put, name, config})
  end

  def get_config(name) do
    GenServer.call(__MODULE__, {:get, name})
  end
end
