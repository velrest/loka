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
    test "creates a studio and sets the owner", %{owner: owner} do
      assert {:ok, studio} = Studios.create_studio(%{name: "My Studio", city: "Zürich", postal_code: "8001"}, actor: owner)
      assert studio.name == "My Studio"
      assert studio.owner_id == owner.id
    end

    test "requires a name", %{owner: owner} do
      assert {:error, error} = Studios.create_studio(%{city: "Zürich", postal_code: "8001"}, actor: owner)
      assert error.errors |> Enum.any?(&match?(%{field: :name}, &1))
    end

    test "requires a city", %{owner: owner} do
      assert {:error, error} = Studios.create_studio(%{name: "My Studio", postal_code: "8001"}, actor: owner)
      assert error.errors |> Enum.any?(&match?(%{field: :city}, &1))
    end

    test "requires a postal code", %{owner: owner} do
      assert {:error, error} = Studios.create_studio(%{name: "My Studio", city: "Zürich"}, actor: owner)
      assert error.errors |> Enum.any?(&match?(%{field: :postal_code}, &1))
    end

    test "requires an actor" do
      assert {:error, _} = Studios.create_studio(%{name: "My Studio", city: "Zürich", postal_code: "8001"})
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
      Studios.create_studio(%{name: "My Studio", city: "Zürich", postal_code: "8001"}, actor: owner)
      assert {:ok, nil} = Studios.get_own_studio(actor: other)
    end
  end

  describe "list_all_studios" do
    test "returns all studios", %{studio: studio, other: other} do
      other_studio = Studios.create_studio!(%{name: "Studio B", city: "Bern", postal_code: "3000"}, actor: other)
      studios = Studios.list_all_studios!()
      ids = Enum.map(studios, & &1.id)
      assert studio.id in ids
      assert other_studio.id in ids
    end
  end

  describe "archive_studio" do
    test "owner can archive their studio", %{owner: owner} do
      {:ok, studio} = Studios.create_studio(%{name: "My Studio", city: "Zürich", postal_code: "8001"}, actor: owner)
      assert {:ok, _} = Studios.archive_studio(studio, actor: owner)
    end

    test "non-owner cannot archive a studio", %{owner: owner, other: other} do
      {:ok, studio} = Studios.create_studio(%{name: "My Studio", city: "Zürich", postal_code: "8001"}, actor: owner)
      assert {:error, _} = Studios.archive_studio(studio, actor: other)
    end
  end
end
