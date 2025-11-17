defmodule OneTimeSecretWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a button.
  """
  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  attr :rest, :global
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input field.
  """
  attr :type, :string, default: "text"
  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :class, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :rest, :global

  def input(assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      value={@value}
      placeholder={@placeholder}
      class={[
        "w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500",
        @class
      ]}
      {@rest}
    />
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-medium text-gray-700 mb-2">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Renders an error message.
  """
  attr :message, :string, required: true

  def error(assigns) do
    ~H"""
    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      <%= @message %>
    </div>
    """
  end

  @doc """
  Renders a success message.
  """
  attr :message, :string, required: true

  def success(assigns) do
    ~H"""
    <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
      <%= @message %>
    </div>
    """
  end
end
