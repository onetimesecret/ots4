defmodule OneTimeWeb.AboutLive do
  use OneTimeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <h1 class="text-4xl font-bold text-gray-900 mb-8">About OneTimeSecret</h1>

      <div class="prose prose-blue max-w-none">
        <p class="text-lg text-gray-700 mb-6">
          OneTimeSecret is a secure, open-source platform for sharing sensitive information
          that can only be viewed once. Built with Elixir and Phoenix, it leverages the power
          of the BEAM VM for reliable, concurrent secret management.
        </p>

        <h2 class="text-2xl font-bold text-gray-900 mt-8 mb-4">How It Works</h2>

        <ol class="list-decimal list-inside space-y-4 text-gray-700">
          <li>
            <strong>Create:</strong> Enter your secret information and optionally set a passphrase
            for additional security. Choose how long the secret should remain accessible.
          </li>
          <li>
            <strong>Share:</strong> You'll receive a unique, one-time URL. Share this link
            with your intended recipient through any communication channel.
          </li>
          <li>
            <strong>View:</strong> When the recipient opens the link, they can view the secret.
            After viewing (or when the time limit expires), the secret is permanently destroyed.
          </li>
        </ol>

        <h2 class="text-2xl font-bold text-gray-900 mt-8 mb-4">Security Features</h2>

        <ul class="list-disc list-inside space-y-2 text-gray-700">
          <li><strong>AES-256-GCM Encryption:</strong> All secrets are encrypted using military-grade encryption</li>
          <li><strong>Zero-Knowledge:</strong> Secrets are encrypted before reaching our servers</li>
          <li><strong>Burn After Reading:</strong> Secrets self-destruct after being viewed</li>
          <li><strong>Time-Limited:</strong> Automatic expiration ensures secrets don't linger</li>
          <li><strong>Passphrase Protection:</strong> Optional additional layer of security</li>
          <li><strong>Rate Limiting:</strong> Protection against abuse and brute-force attacks</li>
        </ul>

        <h2 class="text-2xl font-bold text-gray-900 mt-8 mb-4">Use Cases</h2>

        <ul class="list-disc list-inside space-y-2 text-gray-700">
          <li>Sharing passwords and API keys with team members</li>
          <li>Securely transmitting sensitive configuration data</li>
          <li>Providing temporary access credentials</li>
          <li>Sharing confidential business information</li>
          <li>Transmitting personal identification numbers</li>
        </ul>

        <h2 class="text-2xl font-bold text-gray-900 mt-8 mb-4">Open Source</h2>

        <p class="text-gray-700">
          This is the Community Edition of OneTimeSecret, rebuilt in Elixir/Phoenix.
          The source code is available on GitHub under the MIT License. Contributions
          are welcome!
        </p>

        <div class="mt-8">
          <a
            href="/secret/new"
            class="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700"
          >
            Create Your First Secret
          </a>
        </div>
      </div>
    </div>
    """
  end
end
