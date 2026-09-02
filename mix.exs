defmodule NxAudio.MixProject do
  use Mix.Project

  @source_url "https://github.com/YgorCastor/nx_audio"

  def project do
    [
      app: :nx_audio,
      version: "0.3.2",
      elixir: "~> 1.17",
      aliases: aliases(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [
        plt_core_path: "_plts/core"
      ],
      source_url: @source_url,
      homepage_url: @source_url,
      docs: [
        main: "readme",
        extras: [
          "README.md": [title: "Introduction"],
          "CHANGELOG.md": [title: "Changelog"],
          "./livemd/visualizations.livemd": [title: "Spectrogram Visualizations"],
          LICENSE: [title: "License"]
        ],
        before_closing_head_tag: &before_closing_head_tag/1,
        groups_for_modules: [
          "Error Types": &(&1[:section] == :common_errors),
          "Common Utilities": &(&1[:section] == :common_utils),
          IO: &(&1[:section] == :io),
          Transformations: &(&1[:section] == :transforms),
          Visualizations: &(&1[:section] == :visualizations),
          Codecs: &(&1[:section] == :encodings)
        ],
        nest_modules_by_prefix: [
          NxAudio.Commons.Errors,
          NxAudio.Transforms,
          NxAudio.Visualizations,
          NxAudio.IO.Encoding.Type,
          NxAudio.IO.Backends,
          NxAudio.IO.Errors
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:briefly, "~> 0.5"},
      {:credo, "~> 1.7", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.21", only: [:dev], runtime: false},
      {:enum_type, "~> 1.1"},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:ffmpex, "~> 0.11"},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:nimble_options, "~> 1.1"},
      {:nx, "~> 0.9"},
      {:splode, "~> 0.2"},
      {:vega_lite, "~> 0.1", optional: true}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["test --exclude integration"],
      "test.integration": ["test --only integration"]
    ]
  end

  def cli do
    [preferred_envs: ["test.integration": :test]]
  end

  defp description() do
    "NxAudio is a analogous implementation for the python torchaudio library for NX"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/YgorCastor/nx_audio.git"},
      sponsor: "ycastor.eth"
    ]
  end

  defp before_closing_head_tag(_opts) do
    """
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/katex.min.css" integrity="sha384-vKruj+a13U8yHIkAyGgK1J3ArTLzrFGBbBc0tDp4ad/EyewESeXE/Iv67Aj8gKZ0" crossorigin="anonymous">
      <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/katex.min.js" integrity="sha384-PwRUT/YqbnEjkZO0zZxNqcxACrXe+j766U2amXcgMg5457rve2Y7I6ZJSm2A0mS4" crossorigin="anonymous"></script>

      <link href="https://cdn.jsdelivr.net/npm/katex-copytex@1.0.2/dist/katex-copytex.min.css" rel="stylesheet" type="text/css">
      <script defer src="https://cdn.jsdelivr.net/npm/katex-copytex@1.0.2/dist/katex-copytex.min.js" crossorigin="anonymous"></script>

      <script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.4/dist/contrib/auto-render.min.js" integrity="sha384-+VBxd3r6XgURycqtZ117nYw44OOcIax56Z4dCRWbxyPt0Koah1uHoK0o4+/RRE05" crossorigin="anonymous"
        onload="renderMathInElement(document.body, {
          delimiters: [
            {left: '$$', right: '$$', display: true},
            {left: '$', right: '$', display: false},
          ]
        });"></script>
    """
  end
end
