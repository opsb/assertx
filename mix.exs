defmodule Assertx.MixProject do
  use Mix.Project

  @source_url "https://github.com/opsb/assertx"
  @version "0.1.0"

  def project do
    [
      app: :assertx,
      version: @version,
      elixir: "~> 1.18",
      description: description(),
      package: package(),
      source_url: @source_url,
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [examples: :test]
    ]
  end

  defp description do
    "Composable matchers for ExUnit assertions, inspired by Hamcrest."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "Assertx",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      examples: ["test --only examples --seed 0"]
    ]
  end
end
