defmodule OneTimeWeb.SecretLive.Show do
  use OneTimeWeb, :live_view
  alias OneTime.Secrets

  @impl true
  def mount(%{"key" => key}, _session, socket) do
    case Secrets.get_secret_metadata(key) do
      {:ok, secret} ->
        {:ok,
         socket
         |> assign(:secret, secret)
         |> assign(:key, key)
         |> assign(:revealed, false)
         |> assign(:content, nil)
         |> assign(:passphrase, "")
         |> assign(:error, nil)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Secret not found or has expired")
         |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("reveal", %{"passphrase" => passphrase}, socket) do
    passphrase = if passphrase == "", do: nil, else: passphrase

    case Secrets.get_secret(socket.assigns.key, passphrase) do
      {:ok, _secret, content} ->
        {:noreply,
         socket
         |> assign(:revealed, true)
         |> assign(:content, content)
         |> assign(:error, nil)}

      {:error, :invalid_passphrase} ->
        {:noreply, assign(socket, :error, "Invalid passphrase")}

      {:error, :not_accessible} ->
        {:noreply,
         socket
         |> put_flash(:error, "This secret is no longer accessible")
         |> redirect(to: ~p"/")}

      {:error, reason} ->
        {:noreply, assign(socket, :error, "Error: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <%= if @revealed do %>
        <div class="bg-white shadow rounded-lg p-6">
          <h1 class="text-2xl font-bold text-gray-900 mb-4">Secret Revealed</h1>
          <div class="bg-yellow-50 border border-yellow-200 rounded-md p-4 mb-4">
            <p class="text-yellow-800 text-sm">
              ⚠️ This secret has been revealed and may be destroyed. Copy it now!
            </p>
          </div>
          <div class="bg-gray-50 border border-gray-200 rounded-md p-4 mb-4">
            <pre class="whitespace-pre-wrap break-words text-sm"><%= @content %></pre>
          </div>
          <button
            phx-click={JS.dispatch("phx:copy", to: "#secret-content")}
            class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Copy to Clipboard
          </button>
          <input type="hidden" id="secret-content" value={@content} />
        </div>
      <% else %>
        <div class="bg-white shadow rounded-lg p-6">
          <h1 class="text-2xl font-bold text-gray-900 mb-4">You've Received a Secret</h1>

          <div class="bg-blue-50 border border-blue-200 rounded-md p-4 mb-6">
            <p class="text-blue-800 text-sm">
              This secret can be viewed <%= if @secret.max_views == 1,
                do: "only once",
                else: "#{@secret.max_views - @secret.views_count} more time(s)" %>.
              It will expire on <%= Calendar.strftime(@secret.expires_at, "%B %d, %Y at %I:%M %p UTC") %>.
            </p>
          </div>

          <%= if @secret.passphrase_hash do %>
            <form phx-submit="reveal" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">
                  Enter Passphrase
                </label>
                <input
                  type="password"
                  name="passphrase"
                  placeholder="This secret is protected by a passphrase"
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                  required
                />
              </div>
              <%= if @error do %>
                <div class="text-red-600 text-sm">
                  <%= @error %>
                </div>
              <% end %>
              <button
                type="submit"
                class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Reveal Secret
              </button>
            </form>
          <% else %>
            <form phx-submit="reveal">
              <input type="hidden" name="passphrase" value="" />
              <button
                type="submit"
                class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Reveal Secret
              </button>
            </form>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
