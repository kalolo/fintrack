defmodule Invoices.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Invoices.Repo
  alias Invoices.Accounts.User

  def get_user!(id), do: Repo.get!(User, id)

  def list_users do
    Repo.all(User)
  end

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  def update_user_password(user, current_password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(current_password)

    Repo.update(changeset)
  end

  def reset_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's password directly without any verification.
  This function is intended for administrative use only (e.g., from IEx console).
  It should NOT be exposed through any web API or controller.

  ## Examples

      iex> user = Accounts.get_user_by_email("user@example.com")
      iex> Accounts.admin_reset_password(user, "newpassword123")
      {:ok, %User{}}

  """
  def admin_reset_password(%User{} = user, password) when is_binary(password) do
    user
    |> User.password_changeset(%{"password" => password, "password_confirmation" => password})
    |> Repo.update()
  end
end
