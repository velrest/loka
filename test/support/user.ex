defmodule Loka.Support.UserHelpers do
  @moduledoc false
  use LokaWeb.ConnCase, async: true

  alias Loka.Accounts.User

  def create_user(params \\ %{}) do
    unique_id = System.unique_integer([:positive, :monotonic])

    user =
      User
      |> Ash.Changeset.for_create(
        :register_with_password,
        %{
          email: params[:email] || "email-#{unique_id}@foobar.com",
          password: params[:password] || "password123",
          password_confirmation: params[:password] || "password123"
        },
        authorize?: false
      )
      |> Ash.create!()
  end

  def sign_in(conn, email, password) do
    conn
    |> visit("/sign-in")
    |> within("#user-password-sign-in-with-password", fn session ->
      session
      |> fill_in("Email", with: email)
      |> fill_in("Password", with: password)
      |> click_button("Sign in")
    end)
  end

  def sign_out(conn) do
    conn
    |> visit("/sign-out")
  end
end
