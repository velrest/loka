defmodule Loka.Resources.StudiosTest do
  use Loka.DataCase, async: true

  alias Loka.Studios
  alias Loka.Support.UserHelpers

  setup do
    owner = UserHelpers.create_user()
    other = UserHelpers.create_user()
    %{owner: owner, other: other}
  end

  describe "create_studio" do
    test "creates a studio and sets the owner", %{owner: owner} do
      assert {:ok, studio} = Studios.create_studio(%{name: "My Studio"}, actor: owner)
      assert studio.name == "My Studio"
      assert studio.owner_id == owner.id
    end

    test "requires a name", %{owner: owner} do
      assert {:error, error} = Studios.create_studio(%{}, actor: owner)
      assert error.errors |> Enum.any?(&match?(%{field: :name}, &1))
    end

    test "requires an actor" do
      assert {:error, _} = Studios.create_studio(%{name: "My Studio"})
    end
  end

  describe "get_own_studio" do
    test "returns own studio", %{owner: owner} do
      {:ok, studio} = Studios.create_studio(%{name: "My Studio"}, actor: owner)
      assert {:ok, found} = Studios.get_own_studio(actor: owner)
      assert found.id == studio.id
    end

    test "returns nil when actor has no studio", %{other: other} do
      assert {:ok, nil} = Studios.get_own_studio(actor: other)
    end

    test "does not return another user's studio", %{owner: owner, other: other} do
      Studios.create_studio(%{name: "My Studio"}, actor: owner)
      assert {:ok, nil} = Studios.get_own_studio(actor: other)
    end
  end

  describe "list_all_studios" do
    test "returns all studios", %{owner: owner, other: other} do
      Studios.create_studio(%{name: "Studio A"}, actor: owner)
      Studios.create_studio(%{name: "Studio B"}, actor: other)
      assert {:ok, studios} = Studios.list_all_studios()
      assert length(studios) == 2
    end

    test "returns empty list when no studios exist" do
      assert {:ok, []} = Studios.list_all_studios()
    end
  end

  describe "archive_studio" do
    test "owner can archive their studio", %{owner: owner} do
      {:ok, studio} = Studios.create_studio(%{name: "My Studio"}, actor: owner)
      assert {:ok, _} = Studios.archive_studio(studio, actor: owner)
    end

    test "non-owner cannot archive a studio", %{owner: owner, other: other} do
      {:ok, studio} = Studios.create_studio(%{name: "My Studio"}, actor: owner)
      assert {:error, _} = Studios.archive_studio(studio, actor: other)
    end
  end
end
