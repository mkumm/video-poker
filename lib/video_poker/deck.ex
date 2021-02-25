defmodule VideoPoker.Deck do
  @suits ~w(hearts spades diamonds clubs)a
  @values [2,3,4,5,6,7,8,9,10,11,12,13,14]

  def new() do
    Enum.shuffle(for s <- @suits, v <- @values, do: {v,s})
  end

  def new_hand(), do: Enum.split(new(), 5)

  def empty_hand(), do: [{nil,nil},{nil,nil},{nil,nil},{nil,nil},{nil,nil}]

  def draw(hand, deck, []), do: {hand, deck}
  def draw(hand, deck, positions) do
      [p | ps] = positions
      {card, deck} = take_one(deck)
      hand = List.replace_at(hand, p, card)
      draw(hand, deck, ps)
  end

  def take_one(deck) do
    {[card], deck} =
      deck
      |> Enum.split(1)
    {card, deck}
  end

  def remove_card(hand, pos) do
    List.replace_at(hand, pos, {nil,nil})
  end

  def flush?([{_,a},{_,a},{_,a},{_,a},{_,a}]), do: true
  def flush?(_hand), do: false

  def win_pair?([]), do: false
  def win_pair?([{v,_s}|cs] = _hand) when v >= 11 do
    case Enum.any?(cs, fn {n,_s} -> n == v end) do
      true -> true
      _ -> win_pair?(cs)
    end
  end
  def win_pair?([_|cs] = _hand), do: win_pair?(cs)

  def quads?(hand) do
    hand
    |> face_values()
    |> match_4?()
  end

  defp match_4?([a,a,a,a,_]), do: true
  defp match_4?([_,a,a,a,a]), do: true
  defp match_4?(_), do: false

  def trips?(hand) do
    hand
    |> face_values()
    |> match_3?()
  end


  defp match_3?([]), do: false
  defp match_3?([a,a,a | _]), do: true
  defp match_3?([_|ls]) do
    match_3?(ls)
  end

  def straight?(hand) do
    hand
    |> face_values()
    |> sequence?()
  end

  defp sequence?([_a]), do: true
  defp sequence?([2,3,4,5,14]), do: true
  defp sequence?([a,b|cs]) do
    case b - a == 1 do
      true -> sequence?([b|cs])
      false -> false
    end
  end

  def face_values(hand) do
      Enum.sort(hand)
      |> Enum.map(fn {v,_} -> v end)
  end

  def two_pair?(hand) do
    hand
    |> face_values()
    |> two_pair_check()
  end

  defp two_pair_check([a,a,b,b,_]), do: true
  defp two_pair_check([a,a,_,b,b]), do: true
  defp two_pair_check([_,a,a,b,b]), do: true
  defp two_pair_check(_), do: false

  def full_house?(hand) do
    hand
    |> face_values()
    |> check_full_house()
  end

  defp check_full_house([a,a,a,b,b]), do: true
  defp check_full_house([a,a,b,b,b]), do: true
  defp check_full_house(_), do: false

  def royal?(hand) do
    hand
    |> face_values()
    |> Enum.min()
    |> Kernel.>=(10)
  end

  def royal_flush?(hand) do
    flush?(hand) && royal?(hand)
  end

  def best_hand([]), do: :nothing
  def best_hand(hand) do
    fns = [
      &win_pair?/1,
      &two_pair?/1,
      &trips?/1,
      &straight?/1,
      &flush?/1,
      &full_house?/1,
      &quads?/1,
      &royal_flush?/1
    ]

    case Enum.find(hand, fn x -> x == {nil,nil} end) do
      nil ->
        Enum.map(fns, fn x -> x.(hand) end)
        |> result()
      _ -> :nothing
    end
  end

  def result([false,  false,  false,  false,  false,  false,  false,  false]), do: :high_card
  def result([true,   false,  false,  false,  false,  false,  false,  false]), do: :winning_pair
  def result([_,      true,   false,  false,  false,  false,  false,  false]), do: :two_pair
  def result([_,      _,      true,   false,  false,  false,  false,  false]), do: :trips
  def result([_,      _,      _,      true,   false,  false,  false,  false]), do: :straight
  def result([_,      _,      _,      _,      true,   false,  false,  false]), do: :flush
  def result([_,      _,      _,      _,      _,      true,   false,  false]), do: :full_house
  def result([_,      _,      _,      _,      _,      _,      true,   false]), do: :quads
  def result([_,      _,      _,      true,   true,   false,  false,  false]), do: :straight_flush
  def result([_,      _,      _,      _,      _,      _,      _,      true]),  do: :royal_flush
  def result(_), do: :high_card
end
