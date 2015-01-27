require Logger

defmodule Voter do
  use GenServer

  def start_link(client_pid) do
    GenServer.start_link(__MODULE__, [client_pid], [])
  end

  def init(client_pid) do
    {:ok, client_pid}
  end

  def vote(pid, player_name) do
    GenServer.cast(pid, {:vote, player_name})
  end

  def handle_cast({:vote, player_name}, [client_pid] = state) do
    Logger.info "Voter is Voting for " <> inspect(player_name)
    Philae.DDP.method(client_pid, :vote, [player_name])
    {:noreply, [client_pid]}
  end
end
