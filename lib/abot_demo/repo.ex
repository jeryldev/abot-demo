defmodule AbotDemo.Repo do
  use Ecto.Repo,
    otp_app: :abot_demo,
    adapter: Ecto.Adapters.Postgres
end
