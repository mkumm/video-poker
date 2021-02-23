defmodule VideoPokerWeb.VideoPokerLive do
    use VideoPokerWeb, :live_view

    alias VideoPoker.Deck

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
          hold_cards: hold_cards)
      {:ok, socket}
    end

    def render(assigns) do
      ~L"""
      <h1>Sprytna Video Poker</h1>
      <div class="border">Cash: $<%= @money %>.00</div>
      <button phx-click="add_money">Add $20</button>
      <button phx-click="new">Bet Max $5</button>

      <div class="">
      <%= get_result(@hand) %>
      </div>



      <div class="my-8 flex">

      <%= for {{v,s},i} <- Enum.with_index(@hand,0) do %>
      <div
        phx-click="hold"
        phx-value-pos="<%=i%>"
        class="flex-initial rounded w-48 h-80 p-2 mx-3
          <%= if i in @hold_cards do %>
            font-bold border-4
          <% else %>
            border
          <%end%>">
        <%= v %>-<%=s %>
      </div>
      <% end %>
      </div>

      <%= if @state == :new do %>
      <button phx-click="draw_cards">Draw</button>
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
          hold_cards: [],
          state: :new
        )
      {:noreply, socket}
    end

    def handle_event("draw_cards", _params, socket) do
      money = socket.assigns.money - 5
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
      socket =
        assign(socket,
          money: money,
          hand: hand,
          deck: deck,
          state: :finished
        )
      {:noreply, socket}
    end

    def get_result(hand) do
      Deck.best_hand(hand)
      |> Atom.to_string()
    end
end
