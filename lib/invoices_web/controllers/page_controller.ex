defmodule InvoicesWeb.PageController do
  use InvoicesWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
