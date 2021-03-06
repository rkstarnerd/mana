defmodule ExWire.PeerSupervisor do
  @moduledoc """
  The Peer Supervisor is responsible for maintaining a set of peer TCP
  connections.
  """
  use DynamicSupervisor

  @name __MODULE__

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: @name)
  end

  @doc """
  Creates an outbound connection with peer.

  This function should be called when the Discovery portion of mana discovers new
  nodes.
  """
  def start_child(peer_enode_url) do
    {:ok, peer} = ExWire.Struct.Peer.from_uri(peer_enode_url)

    spec = {ExWire.P2P.Server, [:outbound, peer, [{:server, ExWire.Sync}]]}

    DynamicSupervisor.start_child(@name, spec)
  end

  @doc """
  Sends a packet to all active TCP connections. This is useful when we want to, for instance,
  ask for a `GetBlockBody` from all peers for a given block hash.
  """
  def send_packet(packet) do
    # Send to all of the Supervisor's children...
    # ... not the best.

    for {_id, child, _type, _modules} <- DynamicSupervisor.which_children(@name) do
      # Children which are being restarted by not have a child_pid at this time.
      if is_pid(child), do: ExWire.P2P.Server.send_packet(child, packet)
    end
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
