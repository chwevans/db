defmodule Db.Test.Ets do
  use GenServer
  defstruct query: :undefined

  def start_link, do: GenServer.start_link(__MODULE__, %{}, [])

  def init(%{}) do
    tid = :ets.new(__MODULE__, [:public, :named_table, {:read_concurrency, true}, {:write_concurrency, true}])
    {:ok, tid}
  end
end

defimpl Db.Backend, for: Db.Test.Ets do
  def execute(%Db.Test.Ets{query: {:lookup, key}}) do
    case :ets.lookup(Db.Test.Ets, key) do
      [] -> {:error, :notfound}
      [{^key, value}] -> {:ok, value}
    end
  end

  def execute(%Db.Test.Ets{query: {:insert, key, value}}) do
    :true = :ets.insert(Db.Test.Ets, {key, value})
    :ok
  end
end

ExUnit.start()
Db.Test.Ets.start_link
