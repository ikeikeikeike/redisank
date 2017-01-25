defmodule Redisank do
  defmodule Base do
    use Rdtype,
      uri: Application.get_env(:redisank, :redis)[:ranking],
      coder: Redisank.Coder,
      type: :sorted_set
  end

  @format "{YYYY}{0M}{0D}"

  def namekey(date, key) do
    "#{key}/#{Timex.format! date, @format}"
  end

  def incr(id, time \\ :calendar.local_time)
  def incr(id, time) when is_integer(id) do
    time
    |> Timex.format!(@format)
    |> Base.zincrby(1, id)
  end
  def incr(_, _), do: :error

  def sum(:all), do: sum(nil, :all)
  def sum(time, :all) do
    time = time || :calendar.local_time
    sum time, :weekly
    sum time, :monthly
    sum time, :quarterly
    sum time, :biannually
    sum time, :yearly
  end

  def del(from, to, :daily) do
    date(from, to, :daily)
    |> Base.del
  end

  def del(from, to, :weekly) do
    date(from, to, :weekly)
    |> Base.del
  end

  def del(from, to, :monthly) do
    date(from, to, :monthly)
    |> Base.del
  end

  def date(from, to, :daily) do
    0..abs(Timex.diff(from, to, :days))
    |> Enum.map(&Timex.shift from, days: &1)
    |> Enum.map(&Timex.format! &1, @format)
  end

  def date(from, to, :weekly) do
    0..abs(Timex.diff(from, to, :weeks))
    |> Enum.map(&Timex.shift Timex.beginning_of_week(from), weeks: &1)
    |> Enum.map(&namekey(&1, :weekly))
  end

  def date(from, to, :monthly) do
    0..abs(Timex.diff(from, to, :months))
    |> Enum.map(&Timex.shift Timex.beginning_of_month(from), months: &1)
    |> Enum.map(&namekey(&1, :monthly))
  end

  def sum(:weekly), do: sum(nil, :weekly)
  def sum(time, :weekly) do
    time  = time || :calendar.local_time
    from  = time |> Timex.beginning_of_week
    to    = time |> Timex.end_of_week
    dates = date from, to, :daily

    Base.zunionstore namekey(from, :weekly), dates, aggregate: "sum"
  end

  def sum(:monthly), do: sum(nil, :monthly)
  def sum(time, :monthly) do
    time  = time || :calendar.local_time
    from  = time |> Timex.beginning_of_month
    to    = time |> Timex.end_of_month
    dates = date from, to, :weekly

    Base.zunionstore namekey(from, :monthly), dates, aggregate: "sum"
  end

  def sum(:quarterly), do: sum(nil, :quarterly)
  def sum(time, :quarterly) do
    time  = time || :calendar.local_time
    from  = time |> Timex.beginning_of_quarter
    to    = time |> Timex.end_of_quarter
    dates = date from, to, :monthly

    Base.zunionstore namekey(from, :quarterly), dates, aggregate: "sum"
  end

  def sum(:biannually), do: sum(nil, :biannually)
  def sum(time, :biannually) do
    time = time || :calendar.local_time
    from = time |> beginning_of_biannual
    to   = time |> end_of_biannual

    dates =
      0..Timex.diff(from, to, :months)
      |> Enum.map(&Timex.shift Timex.beginning_of_month(from), months: &1)
      |> Enum.map(&namekey(&1, :quarterly))

    Base.zunionstore namekey(from, :biannually), dates, aggregate: "sum"
  end

  def sum(:yearly), do: sum(nil, :yearly)
  def sum(time, :yearly) do
    time = time || :calendar.local_time
    from = time |> Timex.beginning_of_year
    to   = time |> Timex.end_of_year

    dates =
      0..Timex.diff(from, to, :months)
      |> Enum.map(&Timex.shift Timex.beginning_of_month(from), months: &1)
      |> Enum.map(&namekey(&1, :biannually))

    Base.zunionstore namekey(from, :yearly), dates, aggregate: "sum"
  end

  def top(:all, from, to), do: top :all, from, to, []
  def top(:all, from, to, opts) do
    %{
      weekly: top(:weekly, from, to, opts),
      monthly: top(:monthly, from, to, opts),
      quarterly: top(:quarterly, from, to, opts),
      biannually: top(:biannually, from, to, opts),
      yearly: top(:yearly, from, to, opts),
    }
  end
  def top(key, from, to, opts) do
    time = :calendar.local_time
    key =
      case :"#{key}" do
        :weekly     -> namekey(Timex.beginning_of_week(time), :weekly)
        :monthly    -> namekey(Timex.beginning_of_month(time), :monthly)
        :quarterly  -> namekey(Timex.beginning_of_quarter(time), :quarterly)
        :biannually -> namekey(beginning_of_biannual(time), :biannually)
        :yearly     -> namekey(Timex.beginning_of_year(time), :yearly)
        _           -> key
      end

    score = Keyword.get opts, :withscores, false
    Base.zrevrangebyscore key, "+inf", "-inf", withscores: score, limit: [from, to]
  end
  def top(:all), do: top :all, 0, 50, []
  def top(key),  do: top key, 0, 50, []

  def beginning_of_biannual({{year, month, _}, _}) do
    case month do
      m when m in 1..6  ->
        Timex.beginning_of_month Timex.to_datetime({{year, 1, 1}, {0, 0, 0}})

      m when m in 7..12 ->
        Timex.beginning_of_month Timex.to_datetime({{year, 6, 1}, {0, 0, 0}})
    end
  end
  def end_of_biannual({{year, month, _}, _}) do
    case month do
      m when m in 1..6  ->
        Timex.end_of_month Timex.to_datetime({{year, 6, 1}, {0, 0, 0}})

      m when m in 7..12 ->
        Timex.end_of_month Timex.to_datetime({{year, 12, 1}, {0, 0, 0}})
    end
  end
end
