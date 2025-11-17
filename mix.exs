defmodule OneTimeSecret.MixProject do
  use Mix.Project

  def project do
    [
      app: :onetimesecret,
      version: "1.0.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  def application do
    [
      mod: {OneTimeSecret.Application, []},
      extra_applications: [:logger, :runtime_tools, :mnesia, :crypto]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.0"},

      # Ecto for schema definitions (using with Mnesia adapter)
      {:ecto, "~> 3.11"},
      {:ecto_mnesia, "~> 0.11.0"},

      # Encryption
      {:cloak_ecto, "~> 1.3.0"},

      # Rate limiting
      {:hammer, "~> 6.2"},

      # Testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:stream_data, "~> 1.0", only: :test},
      {:floki, ">= 0.36.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      setup: ["deps.get", "onetimesecret.setup", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind onetimesecret", "esbuild onetimesecret"],
      "assets.deploy": [
        "tailwind onetimesecret --minify",
        "esbuild onetimesecret --minify",
        "phx.digest"
      ],
      test: ["onetimesecret.setup", "test"]
    ]
  end

  # Release configuration
  defp releases do
    [
      onetimesecret: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        steps: [:assemble, :tar]
      ]
    ]
  end
end
