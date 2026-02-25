defmodule LokaWeb.PageController do
  use LokaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
