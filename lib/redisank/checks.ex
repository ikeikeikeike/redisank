defprotocol Redisank.Checks do
  @fallback_to_any true

  def blank?(data)
  def present?(data)
end

defimpl Redisank.Checks, for: Integer do
  alias Redisank.Checks
  def blank?(_),      do: false
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: String do
  alias Redisank.Checks
  def blank?(''),     do: true
  def blank?(' '),    do: true
  def blank?(_),      do: false
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: BitString do
  alias Redisank.Checks
  def blank?(""),     do: true
  def blank?(" "),    do: true
  def blank?(_),      do: false
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: List do
  alias Redisank.Checks
  def blank?([]),     do: true
  def blank?(_),      do: false
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: Tuple do
  alias Redisank.Checks
  def blank?({}),     do: true
  def blank?(_),      do: false
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: Map do
  alias Redisank.Checks
  def blank?(%{}),    do: true
  def blank?(_),      do: false
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: Atom do
  alias Redisank.Checks
  def blank?(false),  do: true
  def blank?(nil),    do: true
  def blank?(_),      do: false
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: MapSet do
  alias Redisank.Checks
  def blank?(data),   do: Enum.empty?(data)
  def present?(data), do: not Checks.blank?(data)
end

defimpl Redisank.Checks, for: Any do
  def blank?(_),      do: false
  def present?(_),    do: false
end
