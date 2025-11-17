defmodule OneTimeWeb.SecretLive.New do
  use OneTimeWeb, :live_view
  alias OneTime.Secrets

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:secret_url, nil)
     |> assign(:form, to_form(%{"content" => "", "ttl" => "604800", "passphrase" => ""}))}
  end

  @impl true
  def handle_event("create", %{"secret" => secret_params}, socket) do
    ttl = String.to_integer(secret_params["ttl"])

    attrs = %{
      content: secret_params["content"],
      ttl: ttl,
      passphrase: if(secret_params["passphrase"] == "", do: nil, else: secret_params["passphrase"]),
      max_views: String.to_integer(secret_params["max_views"] || "1")
    }

    case Secrets.create_secret(attrs) do
      {:ok, secret} ->
        secret_url = url(~p"/secret/#{secret.key}")

        {:noreply,
         socket
         |> assign(:secret_url, secret_url)
         |> put_flash(:info, "Secret created successfully!")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create secret: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">Create a Secret</h1>

      <%= if @secret_url do %>
        <div class="bg-green-50 border border-green-200 rounded-lg p-6 mb-8">
          <h2 class="text-lg font-semibold text-green-900 mb-4">Secret Created!</h2>
          <p class="text-green-800 mb-4">
            Share this link with the recipient. It can only be viewed once!
          </p>
          <div class="flex gap-2">
            <input
              type="text"
              readonly
              value={@secret_url}
              class="flex-1 px-3 py-2 border border-green-300 rounded-md bg-white"
              id="secret-url"
            />
            <button
              phx-click={JS.dispatch("phx:copy", to: "#secret-url")}
              class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
            >
              Copy
            </button>
          </div>
        </div>
      <% else %>
        <.form for={@form} phx-submit="create" class="space-y-6">
          <div>
            <.input
              field={@form[:content]}
              type="textarea"
              label="Secret Content"
              placeholder="Enter your secret message, password, or sensitive data..."
              rows="6"
              required
            />
            <p class="mt-2 text-sm text-gray-500">
              Maximum size: 1 MB
            </p>
          </div>

          <div>
            <.input
              field={@form[:passphrase]}
              type="password"
              label="Passphrase (Optional)"
              placeholder="Additional protection for your secret"
            />
            <p class="mt-2 text-sm text-gray-500">
              If set, the recipient must enter this passphrase to view the secret.
            </p>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Time to Live
              </label>
              <select
                name="secret[ttl]"
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
              >
                <option value="300">5 minutes</option>
                <option value="1800">30 minutes</option>
                <option value="3600">1 hour</option>
                <option value="86400">1 day</option>
                <option value="604800" selected>7 days</option>
                <option value="2592000">30 days</option>
                <option value="7776000">90 days</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Maximum Views
              </label>
              <select
                name="secret[max_views]"
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
              >
                <option value="1" selected>1 view (burn after reading)</option>
                <option value="2">2 views</option>
                <option value="5">5 views</option>
                <option value="10">10 views</option>
              </select>
            </div>
          </div>

          <div>
            <.button type="submit" class="w-full">
              Create Secret
            </.button>
          </div>
        </.form>
      <% end %>
    </div>
    """
  end
end
