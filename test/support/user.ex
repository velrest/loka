defmodule Loka.Support.UserHelpers do
  @moduledoc false
  use LokaWeb.ConnCase, async: true

  alias Loka.Accounts.User

  def create_studio_owner() do
    owner = create_user()
    studio = Loka.Studios.create_studio!(%{name: "My Studio", city: "Zürich", postal_code: "8001"}, actor: owner)
    owner = Ash.load!(owner, [:studio, :has_studio?])
    %{owner: owner, studio: studio}
  end

  def create_user(params \\ %{}) do
    unique_id = System.unique_integer([:positive, :monotonic])

    User
    |> Ash.Changeset.for_create(
      :register_with_password,
      %{
        email: params[:email] || "email-#{unique_id}@foobar.com",
        password: params[:password] || "password123",
        password_confirmation: params[:password] || "password123"
      },
      # no actor exists at registration time in test setup
      authorize?: false
    )
    |> Ash.create!()
    |> Ash.load!(:has_studio?)
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

  def log_in_user(conn, user, password \\ "password123") do
    sign_in(conn, user.email, password).conn
  end
end
