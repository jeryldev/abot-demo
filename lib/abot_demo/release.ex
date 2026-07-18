defmodule AbotDemo.Release do
  @moduledoc false

  def migrate_and_seed do
    load_app()

    for repo <- Application.fetch_env!(:abot_demo, :ecto_repos) do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn repo ->
          Ecto.Migrator.run(repo, :up, all: true)
        end)
    end

    {:ok, _} = Application.ensure_all_started(:abot_demo)
    Code.eval_file(Application.app_dir(:abot_demo, "priv/repo/seeds.exs"))
  end

  defp load_app do
    Application.load(:abot_demo)
  end
end
