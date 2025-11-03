defmodule InvoicesWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use InvoicesWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, :map, default: nil, doc: "the current user"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 relative">
      <div class="flex-1">
        <%!-- <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a> --%>
      </div>
      
    <!-- Desktop Navigation -->
      <div class="hidden md:flex flex-none">
        <%= if @current_user do %>
          <ul class="flex flex-column px-1 space-x-4 items-center">
            <li>
              <.link navigate={~p"/"} class="btn btn-ghost">Invoices</.link>
            </li>
            <li>
              <.link navigate={~p"/transactions"} class="btn btn-ghost">Transactions</.link>
            </li>
            <li>
              <.link navigate={~p"/dashboard"} class="btn btn-ghost">Dashboard</.link>
            </li>
            <li>
              <.link navigate={~p"/investments"} class="btn btn-ghost">Investments</.link>
            </li>
            <li>
              <.theme_toggle />
            </li>
            <li>
              <.link href={~p"/logout"} method="delete" class="btn btn-primary">
                Logout
              </.link>
            </li>
          </ul>
        <% else %>
          <ul class="flex flex-column px-1 space-x-4 items-center">
            <li>
              <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
            </li>
            <li>
              <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
            </li>
            <li>
              <.link navigate={~p"/investments"} class="btn btn-ghost">Investments</.link>
            </li>
            <li>
              <.theme_toggle />
            </li>
            <li>
              <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
                Get Started <span aria-hidden="true">&rarr;</span>
              </a>
            </li>
          </ul>
        <% end %>
      </div>
      
    <!-- Mobile Navigation -->
      <div class="md:hidden flex items-center">
        <.theme_toggle />
        <button
          id="mobile-menu-button"
          class="ml-2 p-2 text-gray-600 hover:text-gray-900 focus:outline-none"
          phx-click={
            JS.toggle(to: "#mobile-menu")
            |> JS.toggle_class("hidden", to: "#mobile-menu")
            |> JS.toggle(to: "#mobile-menu-backdrop")
            |> JS.toggle_class("hidden", to: "#mobile-menu-backdrop")
            |> JS.toggle(to: "#hamburger-icon")
            |> JS.toggle_class("hidden", to: "#hamburger-icon")
            |> JS.toggle(to: "#close-icon")
            |> JS.toggle_class("hidden", to: "#close-icon")
          }
          aria-label="Toggle navigation menu"
        >
          <svg
            id="hamburger-icon"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="w-6 h-6"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
            />
          </svg>
          <svg
            id="close-icon"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="w-6 h-6 hidden"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      
    <!-- Mobile Menu Backdrop -->
      <div
        id="mobile-menu-backdrop"
        class="hidden fixed inset-0 bg-black bg-opacity-50 z-40 md:hidden"
        phx-click={
          JS.hide(to: "#mobile-menu")
          |> JS.add_class("hidden", to: "#mobile-menu")
          |> JS.hide(to: "#mobile-menu-backdrop")
          |> JS.add_class("hidden", to: "#mobile-menu-backdrop")
          |> JS.show(to: "#hamburger-icon")
          |> JS.remove_class("hidden", to: "#hamburger-icon")
          |> JS.hide(to: "#close-icon")
          |> JS.add_class("hidden", to: "#close-icon")
        }
      >
      </div>
      
    <!-- Mobile Menu Overlay -->
      <div
        id="mobile-menu"
        class="hidden md:hidden fixed top-16 left-0 right-0 bg-white shadow-lg border-t z-50 max-h-screen overflow-y-auto"
      >
        <%= if @current_user do %>
          <ul class="flex flex-col py-2">
            <li>
              <.link
                navigate={~p"/"}
                class="block px-4 py-3 text-gray-700 hover:bg-gray-50 border-b border-gray-100 active:bg-gray-100 transition-colors"
                phx-click={
                  JS.hide(to: "#mobile-menu")
                  |> JS.add_class("hidden", to: "#mobile-menu")
                  |> JS.hide(to: "#mobile-menu-backdrop")
                  |> JS.add_class("hidden", to: "#mobile-menu-backdrop")
                  |> JS.show(to: "#hamburger-icon")
                  |> JS.remove_class("hidden", to: "#hamburger-icon")
                  |> JS.hide(to: "#close-icon")
                  |> JS.add_class("hidden", to: "#close-icon")
                }
              >
                Invoices
              </.link>
            </li>
            <li>
              <.link
                navigate={~p"/transactions"}
                class="block px-4 py-3 text-gray-700 hover:bg-gray-50 border-b border-gray-100 active:bg-gray-100 transition-colors"
                phx-click={
                  JS.hide(to: "#mobile-menu")
                  |> JS.add_class("hidden", to: "#mobile-menu")
                  |> JS.hide(to: "#mobile-menu-backdrop")
                  |> JS.add_class("hidden", to: "#mobile-menu-backdrop")
                  |> JS.show(to: "#hamburger-icon")
                  |> JS.remove_class("hidden", to: "#hamburger-icon")
                  |> JS.hide(to: "#close-icon")
                  |> JS.add_class("hidden", to: "#close-icon")
                }
              >
                Transactions
              </.link>
            </li>
            <li>
              <.link
                navigate={~p"/dashboard"}
                class="block px-4 py-3 text-gray-700 hover:bg-gray-50 border-b border-gray-100 active:bg-gray-100 transition-colors"
                phx-click={
                  JS.hide(to: "#mobile-menu")
                  |> JS.add_class("hidden", to: "#mobile-menu")
                  |> JS.hide(to: "#mobile-menu-backdrop")
                  |> JS.add_class("hidden", to: "#mobile-menu-backdrop")
                  |> JS.show(to: "#hamburger-icon")
                  |> JS.remove_class("hidden", to: "#hamburger-icon")
                  |> JS.hide(to: "#close-icon")
                  |> JS.add_class("hidden", to: "#close-icon")
                }
              >
                Dashboard
              </.link>
            </li>
            <li>
              <.link
                navigate={~p"/investments"}
                class="block px-4 py-3 text-gray-700 hover:bg-gray-50 border-b border-gray-100 active:bg-gray-100 transition-colors"
                phx-click={
                  JS.hide(to: "#mobile-menu")
                  |> JS.add_class("hidden", to: "#mobile-menu")
                  |> JS.hide(to: "#mobile-menu-backdrop")
                  |> JS.add_class("hidden", to: "#mobile-menu-backdrop")
                  |> JS.show(to: "#hamburger-icon")
                  |> JS.remove_class("hidden", to: "#hamburger-icon")
                  |> JS.hide(to: "#close-icon")
                  |> JS.add_class("hidden", to: "#close-icon")
                }
              >
                Investments
              </.link>
            </li>
            <li>
              <.link
                href={~p"/logout"}
                method="delete"
                class="block px-4 py-3 text-red-600 hover:bg-red-50 font-semibold active:bg-red-100 transition-colors"
              >
                Logout
              </.link>
            </li>
          </ul>
        <% else %>
          <ul class="flex flex-col py-2">
            <li>
              <a
                href="https://phoenixframework.org/"
                class="block px-4 py-3 text-gray-700 hover:bg-gray-50 border-b border-gray-100 active:bg-gray-100 transition-colors"
              >
                Website
              </a>
            </li>
            <li>
              <a
                href="https://github.com/phoenixframework/phoenix"
                class="block px-4 py-3 text-gray-700 hover:bg-gray-50 border-b border-gray-100 active:bg-gray-100 transition-colors"
              >
                GitHub
              </a>
            </li>
            <li>
              <.link
                navigate={~p"/investments"}
                class="block px-4 py-3 text-gray-700 hover:bg-gray-50 border-b border-gray-100 active:bg-gray-100 transition-colors"
                phx-click={
                  JS.hide(to: "#mobile-menu")
                  |> JS.add_class("hidden", to: "#mobile-menu")
                  |> JS.hide(to: "#mobile-menu-backdrop")
                  |> JS.add_class("hidden", to: "#mobile-menu-backdrop")
                  |> JS.show(to: "#hamburger-icon")
                  |> JS.remove_class("hidden", to: "#hamburger-icon")
                  |> JS.hide(to: "#close-icon")
                  |> JS.add_class("hidden", to: "#close-icon")
                }
              >
                Investments
              </.link>
            </li>
            <li>
              <a
                href="https://hexdocs.pm/phoenix/overview.html"
                class="block px-4 py-3 text-blue-600 hover:bg-blue-50 font-semibold active:bg-blue-100 transition-colors"
              >
                Get Started →
              </a>
            </li>
          </ul>
        <% end %>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-7xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
