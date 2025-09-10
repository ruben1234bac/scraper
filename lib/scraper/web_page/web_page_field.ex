defmodule Scraper.WebPage.WebPageField do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Scraper.WebPage.WebPage

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          value: String.t() | nil,
          full_value: String.t() | nil,
          web_page_id: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @required_fields ~w(name value full_value web_page_id)a

  schema "web_page_fields" do
    field :name, :string
    field :value, :string
    field :full_value, :string

    belongs_to :web_page, WebPage

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.

  ## Examples

      iex> changeset(%WebPageField{}, %{name: "name", value: "value", full_value: "full_value", web_page_id: 1})
      %Ecto.Changeset{data: %WebPageField{}}

  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(web_page_field, attrs) do
    web_page_field
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
