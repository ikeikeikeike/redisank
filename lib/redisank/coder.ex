defmodule Redisank.Coder do
  defmodule Json do
    @behaviour Rdtype.Coder

    def enc(message), do: Poison.encode! message
    def dec(message), do: Poison.decode! message
  end
end
