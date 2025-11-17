defmodule OneTimeSecretWeb.ErrorHTML do
  use OneTimeSecretWeb, :html

  def render("404.html", _assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center">
        <h1 class="text-6xl font-bold text-gray-900">404</h1>
        <p class="text-2xl text-gray-600 mt-4">Page not found</p>
        <a href="/" class="mt-6 inline-block px-6 py-3 bg-blue-600 text-white rounded hover:bg-blue-700">
          Go Home
        </a>
      </div>
    </div>
    """
  end

  def render("500.html", _assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50">
      <div class="text-center">
        <h1 class="text-6xl font-bold text-gray-900">500</h1>
        <p class="text-2xl text-gray-600 mt-4">Internal server error</p>
        <a href="/" class="mt-6 inline-block px-6 py-3 bg-blue-600 text-white rounded hover:bg-blue-700">
          Go Home
        </a>
      </div>
    </div>
    """
  end

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
