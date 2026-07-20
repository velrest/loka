defmodule Loka.Accounts.AdminFlagTest do
  use Loka.DataCase, async: true

  alias Loka.Accounts.User
  alias Loka.Support.UserHelpers

  test "defaults to false" do
    refute UserHelpers.create_user().admin?
  end

  test "is not a public attribute" do
    attribute = Ash.Resource.Info.attribute(User, :admin?)
    refute attribute.public?
  end

  test "no action accepts it, so a user can never set it on themselves" do
    accepting =
      User
      |> Ash.Resource.Info.actions()
      |> Enum.filter(&(:admin? in Map.get(&1, :accept, [])))

    assert accepting == [],
           "actions accept :admin?: #{inspect(Enum.map(accepting, & &1.name))}"
  end

  test "passing admin? at registration is rejected" do
    assert_raise Ash.Error.Invalid, ~r/No such input `admin\?`/, fn ->
      User
      |> Ash.Changeset.for_create(
        :register_with_password,
        %{
          email: "sneaky@foobar.com",
          password: "password123",
          password_confirmation: "password123",
          admin?: true
        },
        authorize?: false
      )
      |> Ash.create!()
    end
  end
end
