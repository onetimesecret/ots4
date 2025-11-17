defmodule OneTimeSecretWeb.API.V2.SecretControllerTest do
  use OneTimeSecretWeb.ConnCase, async: true

  describe "POST /api/v2/share" do
    test "creates a secret", %{conn: conn} do
      params = %{
        "secret" => "my secret content",
        "ttl" => "3600"
      }

      conn = post(conn, ~p"/api/v2/share", params)

      assert %{
               "secret_key" => secret_key,
               "metadata_key" => _metadata_key,
               "ttl" => 3600
             } = json_response(conn, 201)

      assert is_binary(secret_key)
    end

    test "creates a secret with passphrase", %{conn: conn} do
      params = %{
        "secret" => "protected content",
        "passphrase" => "password123",
        "ttl" => "1800"
      }

      conn = post(conn, ~p"/api/v2/share", params)
      assert json_response(conn, 201)
    end
  end

  describe "GET /api/v2/secret/:key" do
    test "retrieves a secret", %{conn: conn} do
      # First create a secret
      create_conn = post(conn, ~p"/api/v2/share", %{"secret" => "test", "ttl" => "3600"})
      %{"secret_key" => key} = json_response(create_conn, 201)

      # Then retrieve it
      conn = get(conn, ~p"/api/v2/secret/#{key}")

      assert %{"secret" => "test"} = json_response(conn, 200)
    end

    test "returns 404 for non-existent secret", %{conn: conn} do
      conn = get(conn, ~p"/api/v2/secret/nonexistent")
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/v2/secret/:key/burn" do
    test "burns a secret", %{conn: conn} do
      # Create a secret
      create_conn = post(conn, ~p"/api/v2/share", %{"secret" => "test", "ttl" => "3600"})
      %{"secret_key" => key} = json_response(create_conn, 201)

      # Burn it
      conn = post(conn, ~p"/api/v2/secret/#{key}/burn")
      assert json_response(conn, 200)

      # Verify it's gone
      conn = get(conn, ~p"/api/v2/secret/#{key}")
      assert json_response(conn, 404)
    end
  end
end
