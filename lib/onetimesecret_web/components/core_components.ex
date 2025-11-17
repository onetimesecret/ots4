defmodule OneTimeSecretWeb.CoreComponents do
  @moduledoc """
  Provides core UI components for OneTimeSecret.
  """
  use Phoenix.Component

  @doc """
  Renders a simple button.
  """
  attr :type, :string, default: "button"
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class={@class}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders flash notifications.
  """
  attr :flash, :map, default: %{}
  attr :kind, :atom

  def flash(assigns) do
    ~H"""
    <div :if={msg = Phoenix.Flash.get(@flash, @kind)} class={"flash flash-#{@kind}"}>
      <p><%= msg %></p>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def header(assigns) do
    ~H"""
    <header class={@class}>
      <h1><%= render_slot(@inner_block) %></h1>
    </header>
    """
  end

  @doc """
  Renders an input field.
  """
  attr :type, :string, default: "text"
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :placeholder, :string, default: ""
  attr :class, :string, default: ""

  def input(assigns) do
    ~H"""
    <input
      type={@type}
      name={@name}
      value={@value}
      placeholder={@placeholder}
      class={@class}
    />
    """
  end
end
