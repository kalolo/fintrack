defmodule FinTrackWeb.AuthLive.Login do
  use FinTrackWeb, :live_view

  def mount(_params, _session, socket) do
    form = to_form(%{"email" => "", "password" => ""}, as: "user")
    {:ok, assign(socket, form: form, page_title: "Log in")}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header>
        Log in to account
        <:subtitle>
          Don't have an account?
          Contact your administrator to create one.
        </:subtitle>
      </.header>

      <.form for={@form} id="login_form" action={~p"/login"} method="post">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <.button phx-disable-with="Logging in..." class="w-full">
          Log in <span aria-hidden="true">→</span>
        </.button>
      </.form>
    </div>
    """
  end
end
