defmodule FinTrackWeb.PageController do
  use FinTrackWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
