defmodule Db.Test do
  use ExUnit.Case
  @behaviour Db
  doctest Db

  defstruct action: :undefined

  test "No route exists when Db.Router isnt implemented" do
    result = Db.execute(:foo, :bar)
    assert {:error, :no_route_found} == result
  end

  test "No route exists when Db.Router is implemented" do
    result = Db.execute(%Db.Test{}, :bar)
    assert {:error, :no_route_found} == result
  end

  test "Inlined write is available immediately" do
    :ok = Db.execute(%Db.Test{action: :write_sync}, {:foo, :bar})
    assert {:ok, :bar} == Db.execute(%Db.Test{action: :read}, :foo)
  end

  test "Non inlined write is available eventually" do
    :ok = Db.execute(%Db.Test{action: :write_async}, {:foo, :bar})
    check({:ok, :bar}, fn() -> Db.execute(%Db.Test{action: :read}, :foo) end)
  end

  def check(result, f), do: check(result, f, 5)

  def check(result, _, 0), do: assert {:error, :no_match} == result
  def check(result, f, tries) do
    test_result = f.()
    case test_result do
      ^result -> assert result == test_result
      ^test_result ->
        :timer.sleep(100)
        check(result, f, tries - 1)
    end
  end

  def handle(%Db.Test{action: :write_async}, args), do: handle(%Db.Test{action: :write_sync}, args)
  def handle(%Db.Test{action: :write_sync}, {key, value}) do
    %Db.Test.Ets{query: {:insert, key, value}}
  end
  def handle(%Db.Test{action: :read}, key) do
    %Db.Test.Ets{query: {:lookup, key}}
  end

  defimpl Db.Router, for: Db.Test do
    def route(%Db.Test{action: :write_async}), do: %Db.Router{module: Db.Test, inline: false}
    def route(%Db.Test{action: :write_sync}), do: %Db.Router{module: Db.Test, inline: true}
    def route(%Db.Test{action: :read}), do: %Db.Router{module: Db.Test, inline: true}
    def route(_), do: {:error, :no_route_found}
  end
end
