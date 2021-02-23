defmodule VideoPoker.Repo do
  use Ecto.Repo,
    otp_app: :video_poker,
    adapter: Ecto.Adapters.Postgres
end
