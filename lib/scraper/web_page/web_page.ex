defmodule Scraper.WebPage.WebPage do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Scraper.Account.User

  alias Scraper.WebPage.WebPageField

  @type t :: %__MODULE__{
          id: integer() | nil,
          url: String.t() | nil,
          title: String.t() | nil,
          user_id: integer() | nil,
          is_completed: boolean() | nil,
          has_failed: boolean() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @required_fields ~w(url user_id)a
  @optional_fields ~w(title is_completed has_failed)a

  schema "web_pages" do
    field :url, :string
    field :title, :string
    field :is_completed, :boolean, default: false
    field :has_failed, :boolean, default: false
    belongs_to :user, User

    has_many :web_page_fields, WebPageField

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.

  ## Examples

      iex> changeset(%WebPage{}, %{url: "url", title: "title", user_id: 1})
      %Ecto.Changeset{data: %WebPage{}}

  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(web_page, attrs) do
    web_page
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
