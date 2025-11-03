defmodule Mix.Tasks.Invoices.CreateUser do
  use Mix.Task

  @shortdoc "Create a user account"
  @moduledoc """
  Create a user account

      $ mix invoices.create_user user@example.com password123

  """

  def run([email, password]) when is_binary(email) and is_binary(password) do
    Mix.Task.run("app.start")

    case Invoices.Accounts.create_user(%{email: email, password: password}) do
      {:ok, user} ->
        Mix.shell().info("User created successfully!")
        Mix.shell().info("Email: #{user.email}")
        Mix.shell().info("ID: #{user.id}")

      {:error, changeset} ->
        Mix.shell().error("Failed to create user:")

        Enum.each(changeset.errors, fn {field, {msg, _}} ->
          Mix.shell().error("  #{field}: #{msg}")
        end)
    end
  end

  def run(_args) do
    Mix.shell().error("Usage: mix invoices.create_user EMAIL PASSWORD")
  end
end
