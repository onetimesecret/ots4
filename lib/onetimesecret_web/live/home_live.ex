defmodule OneTimeSecretWeb.HomeLive do
  use OneTimeSecretWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Home - OneTimeSecret")
     |> assign(:stats, get_stats())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center">
      <h1 class="text-4xl font-bold text-gray-900 mb-6">
        Share Secrets Securely
      </h1>
      <p class="text-xl text-gray-600 mb-8">
        Send passwords, API keys, and sensitive data that self-destruct after viewing
      </p>

      <div class="max-w-md mx-auto space-y-4">
        <a
          href="/create"
          class="block w-full px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-semibold"
        >
          Create a Secret
        </a>
      </div>

      <div class="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white p-6 rounded-lg shadow">
          <div class="text-3xl font-bold text-blue-600 mb-2">🔒</div>
          <h3 class="text-lg font-semibold mb-2">Encrypted</h3>
          <p class="text-gray-600">All secrets are encrypted with AES-256-GCM</p>
        </div>

        <div class="bg-white p-6 rounded-lg shadow">
          <div class="text-3xl font-bold text-blue-600 mb-2">⏰</div>
          <h3 class="text-lg font-semibold mb-2">Temporary</h3>
          <p class="text-gray-600">Secrets automatically expire after viewing or time limit</p>
        </div>

        <div class="bg-white p-6 rounded-lg shadow">
          <div class="text-3xl font-bold text-blue-600 mb-2">🚀</div>
          <h3 class="text-lg font-semibold mb-2">Simple</h3>
          <p class="text-gray-600">Easy to use web interface and REST API</p>
        </div>
      </div>
    </div>
    """
  end

  defp get_stats do
    # You can implement actual stats here
    %{}
  end
end
