defmodule Loka.Repo.Migrations.ItemFirstInventory do
  @moduledoc """
  Makes the inventory item-first:

    * the studio moves from stock to items
    * an item has at most one current (non-archived) stock
    * carts hold items instead of stock (`cart_stock` becomes `cart_items`)

  Generated with `mix ash.codegen item_first_inventory`, then edited by hand to
  carry existing data across.
  """

  use Ecto.Migration

  def up do
    # --- studio: stock -> items

    alter table(:items) do
      add :studio_id,
          references(:studios,
            column: :id,
            name: "items_studio_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    execute """
    UPDATE items SET studio_id = stock.studio_id
    FROM stock WHERE stock.item_id = items.id
    """

    execute "ALTER TABLE items ALTER COLUMN studio_id SET NOT NULL"

    drop_if_exists unique_index(:stock, [:item_id, :studio_id],
                     name: "stock_unique_item_per_studio_index"
                   )

    alter table(:stock) do
      remove :studio_id
    end

    create unique_index(:stock, [:item_id],
             name: "stock_one_current_stock_per_item_index",
             where: "(archived_at IS NULL)"
           )

    # --- carts: cart_stock -> cart_items

    create table(:cart_items, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v7()"), primary_key: true

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :item_id,
          references(:items,
            column: :id,
            name: "cart_items_item_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :cart_id,
          references(:cart,
            column: :id,
            name: "cart_items_cart_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false
    end

    execute """
    INSERT INTO cart_items (id, inserted_at, updated_at, item_id, cart_id)
    SELECT cart_stock.id, cart_stock.inserted_at, cart_stock.updated_at, stock.item_id, cart_stock.cart_id
    FROM cart_stock JOIN stock ON stock.id = cart_stock.stock_id
    """

    drop table(:cart_stock)
  end

  def down do
    # --- carts: cart_items -> cart_stock (only items that still have a current stock)

    create table(:cart_stock, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("uuid_generate_v7()"), primary_key: true

      add :inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :stock_id,
          references(:stock,
            column: :id,
            name: "cart_stock_stock_id_fkey",
            type: :uuid,
            prefix: "public"
          ),
          null: false

      add :cart_id,
          references(:cart,
            column: :id,
            name: "cart_stock_cart_id_fkey",
            type: :uuid,
            prefix: "public",
            on_delete: :delete_all
          ),
          null: false
    end

    execute """
    INSERT INTO cart_stock (id, inserted_at, updated_at, stock_id, cart_id)
    SELECT cart_items.id, cart_items.inserted_at, cart_items.updated_at, stock.id, cart_items.cart_id
    FROM cart_items JOIN stock ON stock.item_id = cart_items.item_id AND stock.archived_at IS NULL
    """

    drop table(:cart_items)

    # --- studio: items -> stock

    drop_if_exists unique_index(:stock, [:item_id],
                     name: "stock_one_current_stock_per_item_index"
                   )

    alter table(:stock) do
      add :studio_id,
          references(:studios,
            column: :id,
            name: "stock_studio_id_fkey",
            type: :uuid,
            prefix: "public"
          )
    end

    execute """
    UPDATE stock SET studio_id = items.studio_id
    FROM items WHERE items.id = stock.item_id
    """

    execute "ALTER TABLE stock ALTER COLUMN studio_id SET NOT NULL"

    create unique_index(:stock, [:item_id, :studio_id],
             name: "stock_unique_item_per_studio_index"
           )

    alter table(:items) do
      remove :studio_id
    end
  end
end
