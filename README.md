# Redisank

A common ranking system on Redis with Plug

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `redisank` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:redisank, "~> 0.1.0"}]
    end
    ```

  2. Ensure `redisank` is started before your application:

    ```elixir
    def application do
      [applications: [:redisank]]
    end
    ```

```elixir
Ranking.top :weekly
Ranking.top :monthly
Ranking.top :quarterly
Ranking.top :biannually
Ranking.top :yearly
Ranking.top :all

from = :calendar.local_time
Ranking.del from, to, :daily
Ranking.del from, to, :weekly
Ranking.del from, to, :monthly

Ranking.sum :weekly
Ranking.sum :monthly
Ranking.sum :quarterly
Ranking.sum :biannually
Ranking.sum :yearly
Ranking.sum :all
```

optional

```elixir
plug Redisank.Plug.Access, [key: "id"] when action in [:show]
```
