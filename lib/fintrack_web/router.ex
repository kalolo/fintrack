defmodule FinTrackWeb.Router do
  use FinTrackWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FinTrackWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug FinTrackWeb.UserAuth, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Routes for unauthenticated users
  scope "/", FinTrackWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{FinTrackWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/login", AuthLive.Login, :new
    end

    post "/login", UserSessionController, :create
  end

  # Routes for authenticated users
  scope "/", FinTrackWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{FinTrackWeb.UserAuth, :ensure_authenticated}] do
      live "/", InvoiceLive.Index, :index
      live "/invoices/new", InvoiceLive.Index, :new
      live "/invoices/:id/edit", InvoiceLive.Index, :edit
      live "/invoices/:id", InvoiceLive.Show, :show

      live "/transactions", TransactionLive.Index, :index
      live "/transactions/new", TransactionLive.Form, :new
      live "/transactions/:id", TransactionLive.Show, :show
      live "/transactions/:id/edit", TransactionLive.Form, :edit

      live "/dashboard", DashboardLive, :index
      live "/investments", InvestmentLive.Index, :index
      live "/investments/:id", InvestmentLive.Index, :show
    end

    # PDF viewing route
    get "/invoices/:id/pdf", PdfController, :show

    delete "/logout", UserSessionController, :delete
  end

  # Add the missing pipelines
  pipeline :redirect_if_user_is_authenticated do
    plug FinTrackWeb.UserAuth, :redirect_if_user_is_authenticated
  end

  pipeline :require_authenticated_user do
    plug FinTrackWeb.UserAuth, :require_authenticated_user
  end

  # Other scopes may use custom stacks.
  # scope "/api", FinTrackWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:fintrack, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FinTrackWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
