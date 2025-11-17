defmodule OneTimeSecretWeb.CreateSecretLive do
  use OneTimeSecretWeb, :live_view

  alias OneTimeSecret.Secrets

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Create Secret")
     |> assign(:secret_created, false)
     |> assign(:secret_key, nil)
     |> assign(:metadata_key, nil)
     |> assign(:error, nil)
     |> assign(:form, to_form(%{"content" => "", "passphrase" => "", "ttl" => "3600"}))}
  end

  @impl true
  def handle_event("create_secret", params, socket) do
    attrs = %{
      content: params["content"],
      passphrase: params["passphrase"],
      ttl: String.to_integer(params["ttl"] || "3600"),
      recipient: params["recipient"]
    }

    case Secrets.create_secret(attrs) do
      {:ok, %{secret: secret, metadata: metadata}} ->
        {:noreply,
         socket
         |> assign(:secret_created, true)
         |> assign(:secret_key, secret.key)
         |> assign(:metadata_key, metadata.key)
         |> assign(:error, nil)}

      {:error, _changeset} ->
        {:noreply, assign(socket, :error, "Failed to create secret. Please try again.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">Create a Secret</h1>

      <%= if @secret_created do %>
        <div class="bg-green-50 border border-green-200 rounded-lg p-6 mb-6">
          <h2 class="text-xl font-semibold text-green-900 mb-4">Secret Created Successfully!</h2>

          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Secret Link</label>
              <div class="flex items-center space-x-2">
                <input
                  type="text"
                  readonly
                  value={"#{OneTimeSecretWeb.Endpoint.url()}/secret/#{@secret_key}"}
                  class="flex-1 px-3 py-2 border border-gray-300 rounded bg-gray-50"
                  id="secret-link"
                />
                <button
                  phx-click={JS.dispatch("phx:copy", to: "#secret-link")}
                  class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Copy
                </button>
              </div>
            </div>

            <div class="bg-yellow-50 border border-yellow-200 rounded p-4">
              <p class="text-sm text-yellow-800">
                ⚠️ This link will only work once! Make sure to share it securely.
              </p>
            </div>

            <button
              phx-click={JS.push("reset")}
              class="w-full px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
            >
              Create Another Secret
            </button>
          </div>
        </div>
      <% else %>
        <%= if @error do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <%= @error %>
          </div>
        <% end %>

        <.form for={@form} phx-submit="create_secret" class="space-y-6">
          <div>
            <.label>Secret Content</.label>
            <textarea
              name="content"
              rows="6"
              required
              placeholder="Enter your secret here..."
              class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            ></textarea>
          </div>

          <div>
            <.label>Passphrase (optional)</.label>
            <.input
              type="password"
              name="passphrase"
              placeholder="Additional protection with a passphrase"
            />
          </div>

          <div>
            <.label>Time to Live</.label>
            <select
              name="ttl"
              class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="300">5 minutes</option>
              <option value="1800">30 minutes</option>
              <option value="3600" selected>1 hour</option>
              <option value="14400">4 hours</option>
              <option value="86400">24 hours</option>
              <option value="604800">7 days</option>
            </select>
          </div>

          <div>
            <.label>Recipient Email (optional)</.label>
            <.input type="email" name="recipient" placeholder="recipient@example.com" />
          </div>

          <.button type="submit" class="w-full">
            Create Secret
          </.button>
        </.form>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("reset", _, socket) do
    {:noreply,
     socket
     |> assign(:secret_created, false)
     |> assign(:secret_key, nil)
     |> assign(:metadata_key, nil)
     |> assign(:error, nil)}
  end
end
