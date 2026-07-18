defmodule AbotDemoWeb.PageController do
  use AbotDemoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
