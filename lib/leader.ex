defmodule Leader do
  use DDPHandler
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init([]) do
    {:ok, client_pid } = Philae.DDP.connect("ws://localhost:3000/websocket", __MODULE__, self)
    {collection, id} = Philae.DDP.subscribe(client_pid, "players")
    {:ok, voter_pid} = Voter.start_link(client_pid)
    {:ok, %{client_pid: client_pid, subscription_id: id, collection: collection, voter_pid: voter_pid}}
  end

  # Client API
  def added(pid, message) do
    GenServer.call(pid, {:added, message})
  end

  def changed(pid, message) do
    GenServer.call(pid, {:changed, message})
  end

  def vote_for_player(pid, player_name) do
    GenServer.call(pid, {:vote, player_name})
    {:ok, []}
  end

  # Server API

  def handle_call({:vote, player_name}, _from, %{client_pid: client_pid} = state) do
    Philae.DDP.method(client_pid, :vote, [player_name])
    {:reply, :ok, state}
  end

  def handle_call({:added, %{"fields" => %{"name" => "Ada Lovelace"}, "id" => id} = message}, _from, state) do
    Logger.info "Yeah! Ada is my favorite"
    Logger.info "In: " <> inspect(message)
    new_state = Map.put_new(state, :ada_id, id)
    {:reply, :ok, new_state}
  end

  def handle_call({:added, message}, _from, state) do
    Logger.info "In: " <> inspect(message)
    {:reply, :ok, state}
  end

  def handle_call({:changed, %{"id" => id} = message}, _from, %{ada_id: ada_id} = state) when id == ada_id do
    Logger.info "YAH another vote for ADA!"
    {:reply, :ok, state}
  end

  def handle_call({:changed, message}, from, %{voter_pid: voter_pid} = state) do
    Logger.info "PlayerVoter recieved changed msg:" <> inspect message
    Logger.info "Voting for Ada!"
    Voter.vote(voter_pid, "Ada Lovelace")
    {:reply, :ok, state}
  end
end
