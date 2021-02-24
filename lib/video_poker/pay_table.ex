defmodule VideoPoker.PayTable do

  def multiplier(:royal_flush), do: 250
  def multiplier(:straight_flush), do: 50
  def multiplier(:quads), do: 30
  def multiplier(:full_house), do: 6
  def multiplier(:flush), do: 5
  def multiplier(:straight), do: 4
  def multiplier(:trips), do: 3
  def multiplier(:two_pair), do: 2
  def multiplier(:winning_pair), do: 1
  def multiplier(_), do: 0

end
