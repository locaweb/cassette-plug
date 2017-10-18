defmodule CassetteMock do
  @moduledoc """
  Test helper module with Cassette-related utility functions
  """

  @valid_ticket "ST-a-valid-ticket"
  @invalid_ticket "ST-an-invalid-ticket"

  def config do
    %{Cassette.Config.default |
      service: "example.org",
      base_url: "http://cas.example.org",
      base_authority: "ACME"
    }
  end

  def valid_ticket, do: @valid_ticket

  def invalid_ticket, do: @invalid_ticket

  def valid_user do
    Cassette.User.new("john.doe", ["ACME_ADMIN"])
  end

  def validate(@valid_ticket, _service) do
    {:ok, valid_user()}
  end

  def validate(@invalid_ticket, _service) do
    {:error, "something is wrong"}
  end
end
