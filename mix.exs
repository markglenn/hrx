defmodule Hrx.MixProject do
  use Mix.Project

  def project do
    [
      app: :hrx,
      name: "hrx",
      version: "0.1.0",
      description: description(),
      source_url: "https://github.com/markglenn/hrx",
      homepage_url: "https://github.com/markglenn/hrx",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: [main: "Hrx", extras: ["README.md"]],
      package: [
        maintainers: ["markglenn@gmail.com"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/markglenn/hrx"}
      ]
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
      {:nimble_parsec, "~> 1.1"},
      {:credo, "~> 1.2", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end

  defp description do
    """
    Human Readable Archive (.hrx) parser for Elixir
    """
  end
end
