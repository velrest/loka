defmodule Loka.Resources.StudiosTest do
  use Loka.DataCase, async: true

  alias Loka.Studios
  alias Loka.Support.UserHelpers

  setup do
    %{owner: owner, studio: studio} = UserHelpers.create_studio_owner()
    other = UserHelpers.create_user()
    %{owner: owner, other: other, studio: studio}
  end

  describe "create_studio" do
    setup do
      %{user: UserHelpers.create_user()}
    end

    test "creates a studio and sets the owner", %{user: user} do
      assert {:ok, studio} =
               Studios.create_studio(%{name: "My Studio", city: "Zürich", postal_code: "8001"},
                 actor: user
               )

      assert studio.name == "My Studio"
      assert studio.owner_id == user.id
    end

    test "requires a name", %{user: user} do
      assert {:error, error} =
               Studios.create_studio(%{city: "Zürich", postal_code: "8001"}, actor: user)

      assert error.errors |> Enum.any?(&match?(%{field: :name}, &1))
    end

    test "requires a city", %{user: user} do
      assert {:error, error} =
               Studios.create_studio(%{name: "My Studio", postal_code: "8001"}, actor: user)

      assert error.errors |> Enum.any?(&match?(%{field: :city}, &1))
    end

    test "requires a postal code", %{user: user} do
      assert {:error, error} =
               Studios.create_studio(%{name: "My Studio", city: "Zürich"}, actor: user)

      assert error.errors |> Enum.any?(&match?(%{field: :postal_code}, &1))
    end

    test "requires an actor" do
      assert {:error, _} =
               Studios.create_studio(%{name: "My Studio", city: "Zürich", postal_code: "8001"})
    end

    test "cannot create a second studio", %{user: user} do
      Studios.create_studio!(%{name: "First Studio", city: "Zürich", postal_code: "8001"},
        actor: user
      )

      assert {:error, _} =
               Studios.create_studio(%{name: "Second Studio", city: "Bern", postal_code: "3000"},
                 actor: user
               )
    end
  end

  describe "get_own_studio" do
    test "returns own studio", %{owner: owner, studio: studio} do
      assert {:ok, found} = Studios.get_own_studio(actor: owner)
      assert found.id == studio.id
    end

    test "returns nil when actor has no studio", %{other: other} do
      assert {:ok, nil} = Studios.get_own_studio(actor: other)
    end

    test "does not return another user's studio", %{owner: owner, other: other} do
      assert owner.studio != nil
      assert {:ok, nil} = Studios.get_own_studio(actor: other)
    end
  end

  describe "list_all_studios" do
    test "returns all studios", %{studio: studio, other: other} do
      other_studio =
        Studios.create_studio!(%{name: "Studio B", city: "Bern", postal_code: "3000"},
          actor: other
        )

      studios = Studios.list_all_studios!()
      ids = Enum.map(studios, & &1.id)
      assert studio.id in ids
      assert other_studio.id in ids
    end
  end

  describe "update_studio" do
    test "owner can update description", %{owner: owner, studio: studio} do
      assert {:ok, updated} =
               Studios.update_studio(studio, %{description: "A great studio"}, actor: owner)

      assert updated.description == "A great studio"
    end

    test "non-owner cannot update studio", %{studio: studio, other: other} do
      assert {:error, _} = Studios.update_studio(studio, %{description: "Hacked"}, actor: other)
    end

    test "geocodes coordinates when postal_code changes", %{owner: owner, studio: studio} do
      assert {:ok, updated} =
               Studios.update_studio(studio, %{postal_code: "8001", city: "Zürich"}, actor: owner)

      assert updated.latitude != nil
      assert updated.longitude != nil
      assert_in_delta updated.latitude, 47.37, 0.1
      assert_in_delta updated.longitude, 8.54, 0.1
    end

    test "does not change coordinates for unknown postal code", %{owner: owner, studio: studio} do
      before_lat = studio.latitude

      {:ok, updated} =
        Studios.update_studio(studio, %{postal_code: "0000", city: "Unknown"}, actor: owner)

      assert updated.latitude == before_lat
    end
  end

  describe "archive_studio" do
    test "owner can archive their studio", %{owner: owner, studio: studio} do
      assert {:ok, _} = Studios.archive_studio(studio, actor: owner)
    end

    test "non-owner cannot archive a studio", %{studio: studio, other: other} do
      assert {:error, _} = Studios.archive_studio(studio, actor: other)
    end
  end
end
