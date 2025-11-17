defmodule OneTimeSecretWeb.SecretLive do
  use OneTimeSecretWeb, :live_view

  alias OneTimeSecret.Secrets

  @impl true
  def mount(%{"key" => key}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "View Secret")
     |> assign(:key, key)
     |> assign(:secret, nil)
     |> assign(:revealed, false)
     |> assign(:error, nil)
     |> assign(:passphrase, "")
     |> assign(:metadata, get_metadata(key))}
  end

  @impl true
  def handle_event("reveal", %{"passphrase" => passphrase}, socket) do
    key = socket.assigns.key

    case Secrets.get_secret(key, if(passphrase == "", do: nil, else: passphrase)) do
      {:ok, secret} ->
        {:noreply,
         socket
         |> assign(:secret, secret)
         |> assign(:revealed, true)
         |> assign(:error, nil)}

      {:error, :not_found} ->
        {:noreply, assign(socket, :error, "Secret not found or already viewed")}

      {:error, :expired} ->
        {:noreply, assign(socket, :error, "This secret has expired")}

      {:error, :invalid_passphrase} ->
        {:noreply, assign(socket, :error, "Invalid passphrase")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto">
      <h1 class="text-3xl font-bold text-gray-900 mb-6">View Secret</h1>

      <%= if @revealed do %>
        <div class="bg-white border border-gray-300 rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">Secret Content</h2>
          <div class="bg-gray-50 border border-gray-200 rounded p-4 mb-4">
            <pre class="whitespace-pre-wrap break-words"><%= @secret.content %></pre>
          </div>

          <div class="bg-red-50 border border-red-200 rounded p-4">
            <p class="text-sm text-red-800">
              🔥 This secret has been viewed and will be destroyed.
            </p>
          </div>
        </div>
      <% else %>
        <%= if @error do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            <%= @error %>
          </div>
        <% end %>

        <%= if @metadata do %>
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
            <h2 class="text-lg font-semibold mb-2">Secret Information</h2>
            <ul class="text-sm text-gray-700 space-y-1">
              <li>Views remaining: <%= @metadata.max_views - @metadata.view_count %></li>
              <li>
                Expires: <%= Calendar.strftime(@metadata.expires_at, "%Y-%m-%d %H:%M UTC") %>
              </li>
              <%= if @metadata.passphrase_required do %>
                <li>🔐 Passphrase required</li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <div class="bg-white border border-gray-300 rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">Reveal Secret</h2>

          <.form for={%{}} phx-submit="reveal" class="space-y-4">
            <%= if @metadata && @metadata.passphrase_required do %>
              <div>
                <.label>Passphrase</.label>
                <.input type="password" name="passphrase" required placeholder="Enter passphrase" />
              </div>
            <% else %>
              <input type="hidden" name="passphrase" value="" />
            <% end %>

            <div class="bg-yellow-50 border border-yellow-200 rounded p-4 mb-4">
              <p class="text-sm text-yellow-800">
                ⚠️ Warning: The secret will be destroyed after viewing!
              </p>
            </div>

            <.button type="submit" class="w-full">
              Reveal Secret
            </.button>
          </.form>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_metadata(key) do
    case Secrets.get_metadata(key) do
      {:ok, metadata} -> metadata
      _ -> nil
    end
  end
end
