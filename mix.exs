defmodule SnmpLib.MixProject do
  use Mix.Project

  def project do
    [
      app: :snmp_lib,
      version: "1.0.8",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      compilers: [:yecc] ++ Mix.compilers(),
      deps: deps(),
      description:
        "Unified SNMP library with PDU encoding/decoding, OID manipulation, and SNMP utilities",
      package: package(),
      docs: [
        main: "SnmpLib",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
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
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:benchee, "~> 1.1", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["SNMP Library Team"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your_org/snmp_lib"}
    ]
  end

  # # Release configuration
  # defp releases do
  #   [
  #     snmp_lib: [
  #       version: "0.2.5",
  #       applications: [snmp_lib: :permanent],
  #       steps: [:assemble, :tar],
  #       strip_beams: Mix.env() == :prod,
  #       include_executables_for: [:unix],
  #       include_erts: true
  #     ]
  #   ]
  # end
end
