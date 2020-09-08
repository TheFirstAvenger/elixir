Code.require_file("../../test_helper.exs", __DIR__)

defmodule Mix.Tasks.Deps.AddTest do
  use ExUnit.Case

  alias Mix.Tasks.Deps.Add

  @mix_exs """
  defmodule DepsAddTest.MixProject do
    defp deps do
      [
        {:foo, "~> 0.8.1"}
      ]
    end
  end
  """

  @mix_exs_empty_deps """
  defmodule DepsAddTest.MixProject do
    defp deps do
      []
    end
  end
  """

  @mix_exs_inline_deps """
  defmodule DepsAddTest.MixProject do
    defp deps do
      [{:foo, "~> 0.8.1"}, {:bar, "~> 0.8.2"}]
    end
  end
  """

  @mix_exs_default_deps """
  defmodule DepsAddTest.MixProject do
    defp deps do
      [
        # {:dep_from_hexpm, "~> 0.3.0"},
        # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      ]
    end
  end
  """

  @mix_exs_missing_deps """
  defmodule DepsAddTest.MixProject do
    def project do
      []
    end
  end
  """

  describe "adding deps with bad values" do
    test "dep already exists" do
      assert_raise Mix.Error, "foo already exists in mix.exs as {:foo, \"~> 0.8.1\"}", fn ->
        Add.add(["foo"], @mix_exs)
      end
    end

    test "non snake-case dep" do
      assert_raise Mix.Error, "Invalid package: \"camelCaseDep\"", fn ->
        Add.add(["camelCaseDep"], @mix_exs)
      end
    end

    test "invalid opt" do
      assert_raise Mix.Error, "Invalid options: [{\"--not-real-opt\", nil}]", fn ->
        Add.add(["bar", "--not-real-opt"], @mix_exs)
      end
    end

    test "both version and path" do
      assert_raise Mix.Error, "Can only specify one of [:version, :path]", fn ->
        Add.add(["bar", "--version", "1.0.0", "--path", "../bar"], @mix_exs)
      end
    end

    test "both path and github" do
      assert_raise Mix.Error, "Can only specify one of [:path, :github]", fn ->
        Add.add(["bar", "--github", "foo/bar", "--path", "../bar"], @mix_exs)
      end
    end

    test "both version and github" do
      assert_raise Mix.Error, "Can only specify one of [:version, :github]", fn ->
        Add.add(["bar", "--version", "1.2.3", "--github", "foo/bar"], @mix_exs)
      end
    end

    test "version, path, and github" do
      assert_raise Mix.Error, "Can only specify one of [:version, :path, :github]", fn ->
        Add.add(
          ["bar", "--version", "1.2.3", "--github", "foo/bar", "--path", "../bar"],
          @mix_exs
        )
      end
    end
  end

  describe "unformatted mix exs" do
    test "one" do
      assert Add.add(["asdf", "--version", "1.0.0"], "\n  " <> @mix_exs) ==
               {:error, :not_formatted}

      assert_received {:mix_shell, :info,
                       [
                         "mix_exs was not formatted. Please run `mix format` and retry, or add this line to mix.exs manually:"
                       ]}

      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\"}"]}

      refute_received _
    end
  end

  describe "missing deps function" do
    test "one" do
      assert Add.add(["foo"], @mix_exs_missing_deps) == {:error, :deps_not_found}

      assert_received {:mix_shell, :info,
                       [
                         "Could not find `defp deps do` in your mix.exs. Please add this line to mix.exs manually:"
                       ]}

      assert_received {:mix_shell, :info, ["{:foo, \">= 0.0.0\"}"]}

      refute_received _
    end
  end

  describe "adding dep" do
    test "with existing" do
      assert Add.add(["asdf", "--version", "1.0.0"], @mix_exs) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0"},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\"}"]}
      refute_received _
    end

    test "without existing" do
      assert Add.add(["asdf", "--version", "1.0.0"], @mix_exs_empty_deps) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\"}"]}
      refute_received _
    end

    test "with existing inline" do
      assert Add.add(["asdf", "--version", "1.0.0"], @mix_exs_inline_deps) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [{:asdf, "~> 1.0.0"}, {:foo, "~> 0.8.1"}, {:bar, "~> 0.8.2"}]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\"}"]}
      refute_received _
    end

    test "with default deps" do
      assert Add.add(["asdf", "--version", "1.0.0"], @mix_exs_default_deps) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0"}
                      # {:dep_from_hexpm, "~> 0.3.0"},
                      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\"}"]}
      refute_received _
    end

    test "with colon on deps arg" do
      assert Add.add([":asdf", "--version", "1.0.0"], @mix_exs) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0"},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\"}"]}
      refute_received _
    end

    test "with 0.0.0" do
      assert Add.add(["asdf", "--version", "0.0.0"], @mix_exs) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, ">= 0.0.0"},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \">= 0.0.0\"}"]}
      refute_received _
    end

    test "with path" do
      assert Add.add([":asdf", "--path", "../asdf_local"], @mix_exs) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, path: "../asdf_local"},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, path: \"../asdf_local\"}"]}

      refute_received _
    end

    test "no runtime" do
      assert Add.add(["asdf", "--version", "1.0.0", "--no-runtime"], @mix_exs) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0", runtime: false},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\", runtime: false}"]}

      refute_received _
    end

    test "only test" do
      assert Add.add(
               ["asdf", "--version", "1.0.0", "--only", "test"],
               @mix_exs_empty_deps
             ) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0", only: :test}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\", only: :test}"]}

      refute_received _
    end

    test "only :test" do
      assert Add.add(
               ["asdf", "--version", "1.0.0", "--only", ":test"],
               @mix_exs_empty_deps
             ) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0", only: :test}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\", only: :test}"]}

      refute_received _
    end

    test "only test and dev" do
      assert Add.add(
               ["asdf", "--version", "1.0.0", "--only", "test", "--only", ":dev"],
               @mix_exs
             ) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, "~> 1.0.0", only: [:test, :dev]},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}
      assert_received {:mix_shell, :info, ["{:asdf, \"~> 1.0.0\", only: [:test, :dev]}"]}

      refute_received _
    end

    test "github" do
      assert Add.add(
               ["asdf", "--github", "asdf-lang/asdf"],
               @mix_exs
             ) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, github: "asdf-lang/asdf"},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}

      assert_received {:mix_shell, :info, ["{:asdf, github: \"asdf-lang/asdf\"}"]}

      refute_received _
    end

    test "github tag" do
      assert Add.add(
               ["asdf", "--github", "asdf-lang/asdf", "--tag", "v1.2.3"],
               @mix_exs
             ) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, github: "asdf-lang/asdf", tag: "v1.2.3"},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}

      assert_received {:mix_shell, :info,
                       [
                         "{:asdf, github: \"asdf-lang/asdf\", tag: \"v1.2.3\"}"
                       ]}

      refute_received _
    end

    test "github ref" do
      assert Add.add(
               ["asdf", "--github", "asdf-lang/asdf", "--ref", "abcdefghi"],
               @mix_exs
             ) ==
               {:ok,
                """
                defmodule DepsAddTest.MixProject do
                  defp deps do
                    [
                      {:asdf, github: "asdf-lang/asdf", ref: "abcdefghi"},
                      {:foo, "~> 0.8.1"}
                    ]
                  end
                end
                """}

      assert_received {:mix_shell, :info, ["Adding new dep:"]}

      assert_received {:mix_shell, :info,
                       [
                         "{:asdf, github: \"asdf-lang/asdf\", ref: \"abcdefghi\"}"
                       ]}

      refute_received _
    end
  end
end
