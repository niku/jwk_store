defmodule JWKStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :jwk_store,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: :dev, runtime: false},
      {:credo, "~> 1.1.0", only: :dev, runtime: false},
      {:bypass, "~> 1.0", only: :test},
      {:jason, "~> 1.1.2"}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [
        :inets
      ]
    ]
  end
end
