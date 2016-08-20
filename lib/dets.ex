defmodule Db.Dets do
  @moduledoc """
  An implementor of Db that provides a dets table as a backend.

  This currently provides a means to lookup a key, delete a value associated with a key,
  and insert values associated with keys. Values can be keyspaced by the keyspace argument,
  but by default are available everywhere.
  """
  use GenServer
  require Logger

  defstruct keyspace: :global, query: :undefined

  def start_link do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  def init(_) do
    {:ok, tid} = :dets.open_file(__MODULE__, [access: :read_write, repair: true])
    {:ok, tid}
  end

  def handle_call(m = %Db.Dets{}, _from, tid) do
    reply = handle(m, tid)
    {:reply, reply, tid}
  end

  def terminate(_reason, tid) do
    # TODO: GHI:1 This isn't currently being called, but should be handled when clean node shutdown is implemented
    Logger.info("Shutting down #{inspect __MODULE__}, closing dets")
    :ok = :dets.close(tid)
  end

  defp ets_key(keyspace, key), do: {keyspace, key}

  defp handle(%Db.Dets{keyspace: keyspace, query: {:lookup, key}}, tid) do
    k = ets_key(keyspace, key)
    case :dets.lookup(tid, k) do
      [] -> {:error, :notfound}
      [{k, i}] -> {:ok, i}
    end
  end
  defp handle(%Db.Dets{keyspace: keyspace, query: {:insert, key, value}}, tid) do
    :ok = :dets.insert(tid, {ets_key(keyspace, key), value})
    :ok = :dets.sync(tid)
    :ok
  end
  defp handle(%Db.Dets{keyspace: keyspace, query: {:delete, key}}, tid) do
    :ok = :dets.delete(tid, ets_key(keyspace, key))
    :ok = :dets.sync(tid)
    :ok
  end

  # Special actions that don't correspond to one ets operation
  defp handle(%Db.Dets{keyspace: keyspace, query: {:insert_list, key, value}}, tid) do
    case handle(%Db.Dets{keyspace: keyspace, query: {:lookup, key}}, tid) do
      {:ok, items} -> handle(%Db.Dets{keyspace: keyspace, query: {:insert, key, Enum.uniq([value | items])}}, tid)
      {:error, :notfound} -> handle(%Db.Dets{keyspace: keyspace, query: {:insert, key, [value]}}, tid)
    end
  end
  defp handle(%Db.Dets{keyspace: keyspace, query: {:delete_list, key, value}}, tid) do
    case handle(%Db.Dets{keyspace: keyspace, query: {:lookup, key}}, tid) do
      {:ok, items} -> handle(%Db.Dets{keyspace: keyspace, query: {:insert, key, Enum.uniq(items -- [value])}}, tid)
      {:error, :notfound} -> :ok
    end
  end
end

defimpl Db.Backend, for: Db.Dets do
  def execute(query) do
    GenServer.call(Db.Dets, query, 1000)
  end
end
