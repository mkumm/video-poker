defmodule VideoPokerWeb.VideoPokerLive do
    use VideoPokerWeb, :live_view

    alias VideoPoker.{Deck, PayTable}

    def mount(_params, _session, socket) do
      money = 0
      hand = []
      deck = []
      state = :start
      hold_cards = []
      socket =
        assign(socket,
          money: money,
          hand: hand,
          deck: deck,
          state: state,
          result: :none,
          winnings: 0,
          hold_cards: hold_cards)
      {:ok, socket}
    end

    def render(assigns) do
      ~L"""



      <table class="paytable">
      <tr <%= if @result == :royal_flush do %>class="font-bold win_line" <% end %>>
        <td>Royal Flush</td><td>4000</td>
        </tr>
        <tr <%= if @result == :straight_flush do %>class="font-bold win_line" <% end %>>
        <td>Straight Flush</td><td>250</td>
        </tr>
        <tr <%= if @result == :quads do %>class="font-bold win_line" <% end %>>
        <td>4 of a Kind</td><td>150</td>
        </tr>
        <tr <%= if @result == :full_house do %>class="font-bold win_line" <% end %> >

        <td>Full House</td><td>30</td>
        </tr>
        <tr <%= if @result == :flush do %>class="font-bold win_line" <% end %>>
        <td>Flush</td><td>25</td>
        </tr>
        <tr <%= if @result == :straight do %>class="font-bold win_line" <% end %>>
        <td>Straight</td><td>20</td>
        </tr>
        <tr <%= if @result == :trips do %>class="font-bold win_line" <% end %>>
        <td>3 of a Kind</td><td>15</td>
        </tr>
        <tr <%= if @result == :two_pair do %>class="font-bold win_line" <% end %>>
        <td>Two Pair</td><td>10</td>
        </tr>
        <tr <%= if @result == :winning_pair do %>class="font-bold win_line" <% end %>>
        <td>Jacks or Better</td><td>5</td>
        </tr>

      </table>






      <div class="grid grid-cols-5 pb-8 content-center">
        <%= if @state == :start do %>

          <div class="p-2 mx-3 card">
            <img src="images/cards/back.svg" />
          </div>
          <div class="p-2 mx-3 card">
            <img src="images/cards/back.svg" />
          </div>
          <div class="p-2 mx-3 card">
            <img src="images/cards/back.svg" />
          </div>
          <div class="p-2 mx-3 card">
            <img src="images/cards/back.svg" />
          </div>
          <div class="p-2 mx-3 card">
            <img src="images/cards/back.svg" />
          </div>
        <% else %>


          <%= for {{v,s},i} <- Enum.with_index(@hand,0) do %>
            <div
              phx-click="hold"
              phx-value-pos="<%=i%>"
              class="p-2 mx-3
                <%= if i in @hold_cards do %>
                  card-selected
                <% else %>
                  card
                <%end%>">
                <img src="<%=img_from(v,s)%>" />
            </div>
          <% end %>
        <% end %>
      </div>

      <div class="status grid grid-cols-3 gap-8 pb-12">
        <div class="bg-white border rounded-lg p-6"><%= get_result(@hand) %></div>
        <div class="bg-white border rounded-lg p-6 text-center">
        <%= if @winnings > 0 do %>
            Won <%= @winnings %>
        <% else %>
            Bet 5
        <% end %>
        </div>

        <div class="bg-white border rounded-lg p-6 text-right">$<%= @money %></div>

      </div>

      <div class="status grid grid-cols-5 gap-8 pb-12">

      <button phx-click="add_money">Add $20</button>
      <%= if @money > 0 do %>
      <button class="btn btn--primary" phx-click="new">Bet 1</button>
      <button phx-click="new">Max Bet</button>
      <% else %>
      <button></button>
      <button></button>
      <% end %>
      <div></div>
      <%= if @state == :new do %>
      <button phx-click="draw_cards">Deal</button>
      <% else %>
      <button></button>
      <% end %>

      """
    end

    def handle_event("add_money", _params, socket) do
      socket = assign(socket, money: socket.assigns.money+20)
      {:noreply, socket}
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

    def handle_event("new", _params, socket) do
      money = socket.assigns.money - 5
      {hand, deck} = Deck.new_hand()
      socket =
        assign(socket,
          money: money,
          hand: hand,
          deck: deck,
          winnings: 0,
          hold_cards: [],
          result: Deck.best_hand(hand),
          state: :new
        )
      {:noreply, socket}
    end

    def handle_event("draw_cards", _params, socket) do
      money = socket.assigns.money
      replace_cards =
        Enum.filter(
          [0,1,2,3,4],
          fn x -> x not in socket.assigns.hold_cards
        end)

      {hand, deck} =
        Deck.draw(
          socket.assigns.hand,
          socket.assigns.deck,
          replace_cards
        )
      winnings = PayTable.multiplier(Deck.best_hand(hand))

      socket =
        assign(socket,
          money: money + (winnings * 5),
          hand: hand,
          deck: deck,
          winnings: winnings * 5,
          result: Deck.best_hand(hand),
          state: :finished
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
