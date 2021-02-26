defmodule VideoPokerWeb.VideoPokerLive do
    use VideoPokerWeb, :live_view

    alias VideoPoker.{Deck, PayTable}

    def mount(_params, _session, socket) do
      socket =
        assign(socket,
          stats_games_played: 0,
          stats_money_added: 0,
          stats_games_won: 0,
          stats_credits_played: 0,
          stats_credits_won: 0,
          money: 0,
          bet: 0,
          hand: Deck.empty_hand(),
          deck: [],
          state: :new,
          result: :none,
          winnings: 0,
          hold_cards: [])
      {:ok, socket}
    end

    def render(assigns) do
      ~L"""

      <div class="grid md:grid-cols-2 gap-4 pb-4 grid-cols-1">
        <div class="col-span-1 border-4 bg-white p-6 rounded-xl">
        <h2 class="font-bold md:text-xl pb-3">Pay Table</h2>
          <table class="paytable w-full">
            <tr <%= if @result == :royal_flush do %>class="font-bold win_line" <% end %>>
            <td>Royal Flush</td><td class="text-right"><%= max(@bet * 250, 250) %></td>
            </tr>
            <tr <%= if @result == :straight_flush do %>class="font-bold win_line" <% end %>>
            <td>Straight Flush</td><td class="text-right"><%= max(@bet * 50, 50) %></td>
            </tr>
            <tr <%= if @result == :quads do %>class="font-bold win_line" <% end %>>
            <td>4 of a Kind</td><td class="text-right"><%= max(@bet * 30, 30) %></td>
            </tr>
            <tr <%= if @result == :full_house do %>class="font-bold win_line" <% end %> >
            <td>Full House</td><td class="text-right"><%= max(@bet * 6, 6) %></td>
            </tr>
            <tr <%= if @result == :flush do %>class="font-bold win_line" <% end %>>
            <td>Flush</td><td class="text-right"><%= max(@bet * 5, 5) %></td>
            </tr>
            <tr <%= if @result == :straight do %>class="font-bold win_line" <% end %>>
            <td>Straight</td><td class="text-right"><%= max(@bet * 4, 4) %></td>
            </tr>
            <tr <%= if @result == :trips do %>class="font-bold win_line" <% end %>>
            <td>3 of a Kind</td><td class="text-right"><%= max(@bet * 3, 3) %></td>
            </tr>
            <tr <%= if @result == :two_pair do %>class="font-bold win_line" <% end %>>
            <td>Two Pair</td><td class="text-right"><%= max(@bet * 2, 2) %></td>
            </tr>
            <tr <%= if @result == :winning_pair do %>class="font-bold win_line" <% end %>>
            <td>Jacks or Better</td><td class="text-right"><%= max(@bet * 1, 1) %></td>
            </tr>
          </table>
        </div>
        <div class="col-span-1 border-4 bg-white p-6 rounded-xl md:block hidden">
          <h2 class="font-bold text-xl pb-3">Stats</h2>
          <table class="stats w-full">
          <tr>
          <td>Games Played</td><td class="text-right"> <%= @stats_games_played %></td>
          </tr>
          <tr>
          <td>Games Won</td><td class="text-right"><%= @stats_games_won %></td>
          </tr>
          <tr>
          <td>Credits Added</td><td class="text-right"><%= @stats_money_added %></td>
          </tr>
          <tr>
          <td>Credits Played</td><td class="text-right"><%= @stats_credits_played %></td>
          </tr>
          <tr>
          <td>Credits Won</td><td class="text-right"><%= @stats_credits_won %></td>
          </tr>
          </table>
        </div>
      </div>

      <div class="grid grid-cols-5 md:gap-3 pb-3 content-center">

          <%= for {{v,s},i} <- Enum.with_index(@hand,0) do %>
            <div <%= if @state == :deal do %>phx-click="hold" phx-value-pos="<%=i%>"<%end%>
                  class="
                    <%= if i in @hold_cards do %>
                      card-selected
                    <% else %>
                      card
                    <%end%>">
              <%= if v == nil do %>
              <img src="images/cards/back.svg" />
              <% else %>
              <img src="<%=img_from(v,s)%>" />
              <% end %>
            </div>
          <% end %>

      </div>

      <div class="status grid grid-cols-3 md:gap-8 gap-2 m-3 pb-3">
        <div class="status-box">
          Won:
            <span class="block float-right text-right">
              <%= if @winnings > 0 do%>
                <%= @winnings %>
              <% else %>
                - -
              <% end %>
            </span>
          </div>
        <div class="status-box">Bet: <span class="block float-right text-right"><%= @bet %></span></div>
        <div class="status-box">Credit: <span class="block float-right text-right"><%= @money %></span></div>
      </div>

      <div class="grid grid-cols-5 md:gap-8 gap-1 m-3">
        <button phx-click="add_money"><span>Add 20</span></button>

        <%= cond do %>
          <% @money > 0 and @state != :deal -> %>
            <button phx-click="bet1">Bet 1</button>
            <%= if @money < 5 do %>
              <button></button>
            <% else %>
              <button phx-click="betmax">Max Bet</button>
            <% end %>

          <% true -> %>
            <button></button>
            <button></button>
          <% end %>

        <div></div>
        <%= cond do %>
          <% @state in [:new, :draw, :finished] -> %>
            <button></button>
          <% @state == :bet -> %>
            <button phx-click="deal">Deal</button>
          <% true -> %>
            <button phx-click="draw">Draw</button>
        <% end %>


      """
    end


    def handle_event("add_money", _params, socket) do
      socket = assign(socket,
        money: socket.assigns.money+20,
        stats_money_added: socket.assigns.stats_money_added+20)
      {:noreply, socket}
    end

    def handle_event("bet1", _params, socket) do

      bet =
        if(socket.assigns.state == :finished) do
          1
        else
          socket.assigns.bet + 1
        end

      money = socket.assigns.money - 1
      {:noreply, assign(socket, bet: bet, money: money, state: :bet)}
    end

    def handle_event("betmax", _params, socket) do
      bet = 5
      money = socket.assigns.money - 5
      send(self(), :deal)
      {:noreply, assign(socket, state: :bet, bet: bet, money: money)}
    end

    def handle_event("deal", _params, socket) do
      send(self(), :deal)
      {:noreply, assign(socket, state: :deal)}
    end

    def handle_event("draw", _params, socket) do
      send(self(), :draw_cards)
      {:noreply, assign(socket, state: :draw)}
    end

    def handle_event("hold", %{"pos" => pos}, socket) do
      pos =
        String.to_integer(pos)

      hold_cards =
        case pos in socket.assigns.hold_cards do
          false -> [pos | socket.assigns.hold_cards]
          _ -> List.delete(socket.assigns.hold_cards, pos)
        end

      socket = assign(socket, hold_cards: hold_cards)
      {:noreply, socket}
    end

    def handle_info(:deal, socket) do


      deck = Deck.new()
      hand = [{nil,nil},{nil,nil},{nil,nil},{nil,nil},{nil,nil}]

      Enum.each([0,1,2,3,4], fn x ->
        send(self(), {:draw_card, x})
      end)

      send(self(), :init_draw)

      socket =
        assign(socket,

          hand: hand,
          deck: deck,
          winnings: 0,
          hold_cards: [],
          result: Deck.best_hand(hand),
          state: :deal
        )
      {:noreply, socket}
    end



    def handle_info(:draw_cards,  socket) do

      replace_cards =
        Enum.filter(
          [0,1,2,3,4],
          fn x -> x not in socket.assigns.hold_cards
        end)

      Enum.each(replace_cards, fn x ->
        send(self(), {:remove_card, x})
      end)

      Enum.each(replace_cards, fn x ->
        send(self(), {:draw_card, x})
      end)

      send(self(), :check_results)

      socket = assign(socket, hold_cards: [])

      {:noreply, socket}
    end

    def handle_info(:init_draw, socket) do
      result = Deck.best_hand(socket.assigns.hand)
      socket = assign(socket, result: result)
      {:noreply, socket}
    end

    def handle_info({:remove_card, pos}, socket) do
      hand = Deck.remove_card(socket.assigns.hand, pos)
      socket = assign(socket, hand: hand)
      {:noreply, socket}
    end

    def handle_info({:draw_card, pos}, socket) do
      :timer.sleep(250)
      {hand, deck} = Deck.draw(socket.assigns.hand, socket.assigns.deck, [pos])
      socket = assign(socket, hand: hand, deck: deck)
      {:noreply, socket}
    end

    def handle_info(:check_results, socket) do
      result = Deck.best_hand(socket.assigns.hand)
      winnings = PayTable.multiplier(Deck.best_hand(socket.assigns.hand))
      games_won = socket.assigns.stats_games_won + min(winnings,1)
      money = winnings * socket.assigns.bet + socket.assigns.money
      socket = assign(socket,
        result: result,
        winnings: winnings * socket.assigns.bet,
        state: :finished,
        money: money,
        stats_games_won: games_won,
        stats_games_played: socket.assigns.stats_games_played + 1,
        stats_credits_played: socket.assigns.bet + socket.assigns.stats_credits_played,
        stats_credits_won: socket.assigns.stats_credits_won + winnings * socket.assigns.bet
        )
      {:noreply, socket}
    end

    def get_result(hand) do
      Deck.best_hand(hand)
      |> results()
    end

    def img_from(value, suit) do
      value =
        case value do
          14 -> "ace"
          13 -> "king"
          12 -> "queen"
          11 -> "jack"
          a -> Integer.to_string(a)
        end

      suit = Atom.to_string(suit)

      "images/cards/#{value}-#{suit}.svg"
    end

    def results(:high_card), do: "High Card"
    def results(:winning_pair), do: "Jacks or Better"
    def results(:two_pair), do: "Two Pair"
    def results(:trips), do: "Three of a Kind"
    def results(:straight), do: "Straight"
    def results(:flush), do: "Flush"
    def results(:full_house), do: "Full House"
    def results(:quads), do: "Four of a Kind"
    def results(:straight_flush), do: "Striaght Flush"
    def results(:royal_flush), do: "Royal Flush"
    def results(_), do: ""
end
