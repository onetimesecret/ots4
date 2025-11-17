defmodule OneTimeWeb.HomeLive do
  use OneTimeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center">
      <h1 class="text-4xl font-bold tracking-tight text-gray-900 sm:text-6xl">
        Share Secrets Securely
      </h1>
      <p class="mt-6 text-lg leading-8 text-gray-600">
        OneTimeSecret allows you to share sensitive information that can only be viewed once.
        Perfect for passwords, API keys, and other confidential data.
      </p>
      <div class="mt-10 flex items-center justify-center gap-x-6">
        <a
          href="/secret/new"
          class="rounded-md bg-blue-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
        >
          Create a Secret
        </a>
        <a href="/about" class="text-sm font-semibold leading-6 text-gray-900">
          Learn more <span aria-hidden="true">→</span>
        </a>
      </div>
    </div>

    <div class="mt-16 grid grid-cols-1 gap-8 sm:grid-cols-3">
      <div class="bg-white p-6 rounded-lg shadow">
        <div class="text-blue-600 text-3xl mb-4">🔒</div>
        <h3 class="text-lg font-semibold mb-2">Secure Encryption</h3>
        <p class="text-gray-600">
          All secrets are encrypted using AES-256-GCM before storage. Your data is safe.
        </p>
      </div>

      <div class="bg-white p-6 rounded-lg shadow">
        <div class="text-blue-600 text-3xl mb-4">🔥</div>
        <h3 class="text-lg font-semibold mb-2">Burn After Reading</h3>
        <p class="text-gray-600">
          Secrets automatically self-destruct after being viewed, ensuring one-time access.
        </p>
      </div>

      <div class="bg-white p-6 rounded-lg shadow">
        <div class="text-blue-600 text-3xl mb-4">⏰</div>
        <h3 class="text-lg font-semibold mb-2">Time Limited</h3>
        <p class="text-gray-600">
          Set an expiration time for your secrets. They're automatically deleted when expired.
        </p>
      </div>
    </div>
    """
  end
end
