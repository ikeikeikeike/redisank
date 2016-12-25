defmodule Redisank.Plug.Access do
  import Plug.Conn
  import Redisank.Checks, only: [present?: 1]

  def init(opts), do: opts
  def call(conn, opts) do
    id = conn.params[opts[:key]]

    case Integer.parse(id) do
      {id, _} ->
        if present?(id), do: Redisank.incr id
      :error   ->
        nil
    end

    conn
  end
end
