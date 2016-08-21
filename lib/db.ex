defprotocol Db.Backend do
  @doc """
  When implementing access to a new type of database, a struct containing query information should be created.
  The db framework has a module generate a query and returns it to route through the protocol.

  Whatever is returned by execute will be returned to the client unless the query is not inlined in which case
  :ok will be returned.

  The general guideline is that a protocol implementor should return :ok for insertions and deletions and
  {:ok, any} for lookups. If an object isn't present, {:error, :notfound} should be used.
  In the case of general errors, {:error, any} should be returned.
  """
  def execute(any)
end

defprotocol Db.Router do
  @doc """
  Return a module that implements Db.

  If there is no matching term, route should return {:error, :no_route_found}.
  """
  defstruct module: :undefined, inline: true

  def route(any)
end

defmodule Db do
  @moduledoc """
  All database access goes through this module.

  This is a convenient location to record metrics and implement access to other databases.
  This provides an interface to a dets table.
  """
  require Logger

  @doc """
  Return a query to be handled by implementors of Db.Backend.
  The first argument passed in is the command passed in to Db.execute,
  and the second argument is the data required.
  """
  @callback handle(any, any) :: any

  @spec execute(atom, any) :: :ok | {:ok, any} | {:error, :notfound | :no_route_found} | {:error, any}
  def execute(command, args) do
    try do
      case Db.Router.route(command) do
        e = {:error, :no_route_found} -> e
        route = %Db.Router{inline: inline} ->
          case inline do
            true -> handle_execute(route, command, args)
            false ->
              spawn(fn -> handle_execute(route, command, args) end)
              :ok
          end
      end
    rescue
      _ in Protocol.UndefinedError -> {:error, :no_route_found}
    end
  end

  @spec handle_execute(%Db.Router{}, any, any) :: :ok | {:ok, any} | {:error, :notfound | :no_route_found} | {:error, any}
  defp handle_execute(%Db.Router{module: module}, command, args) do
    query = module.handle(command, args)
    Db.Backend.execute(query)
  end
end
