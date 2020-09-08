defmodule Mix.Tasks.Deps.Add do
  use Mix.Task

  @shortdoc "Adds the specified dependency"

  @moduledoc """
  Adds the given dependency to mix.exs.

  The given dependency will be added to mix.exs at the given version, or the
  latest version available on hex if no version is specified. Alternatively a
  path can be specified instead of a version. `runtime: false` and `only: :env`
  can also be specified by the below options.

  ## Command line options

    * `--version` - version to add (defaults to latest available on hex)
    * `--only` - Adds the only: :env option to the dependency
    * `--no-runtime - Adds the runtime: false option to the dependency
    * `--path` - Adds the `path: "path"` option to the dependency instead of `version:`

  ## Notes

  --version will automatically add "~> " to the front of the version unless the
  version is `0.0.0`, in which case it will use `>= 0.0.0`

  --only` supports multiple values in this format:

    `mix deps.add foo --only test --only dev

  `mix deps.add` requires the standard deps function in your mix.exs file in one of these formats:

      defp deps do
        [
          ...

  or
      defp deps do
        []
      ...

  """

  @snake_case_regex ~r/^[a-z|_]+$/

  @impl true
  def run(args) do
    case add(args, File.read!("mix.exs")) do
      {:ok, mix_exs} ->
        File.write!("mix.exs", mix_exs)
        Mix.shell().info([:green, "Successfully added to mix.exs"])

      {:error, reason} ->
        {:error, reason}
    end
  end

  def add(args, mix_exs) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          version: :string,
          only: :keep,
          runtime: :boolean,
          path: :string,
          github: :string,
          ref: :string,
          tag: :string
        ]
      )

    app =
      case rest do
        [binary] when is_binary(binary) ->
          binary

        _ ->
          Mix.raise("Invalid options: #{inspect(rest)}")
      end

    if invalid != [], do: Mix.raise("Invalid options: #{inspect(invalid)}")

    [:version, :path, :github]
    |> Enum.filter(&(!is_nil(opts[&1])))
    |> case do
      [_, _ | _] = all ->
        Mix.raise("Can only specify one of #{inspect(all)}")

      _ ->
        :ok
    end

    if is_nil(opts[:github]) && !is_nil(opts[:tag]),
      do: Mix.raise("tag option requires github option")

    if is_nil(opts[:github]) && !is_nil(opts[:ref]),
      do: Mix.raise("ref option requires github option")

    app = normalize_atom(app, "package")

    only =
      case Keyword.get_values(opts, :only) do
        nil -> []
        env when is_binary(env) -> [normalize_atom(env, "only")]
        envs when is_list(envs) -> Enum.map(envs, &normalize_atom(&1, "only"))
      end

    opts = Keyword.put(opts, :only, only)

    case Mix.Dep.add(app, opts, mix_exs) do
      {:ok, new_line, new_mix_exs} ->
        Mix.shell().info("Adding new dep:")
        Mix.shell().info(new_line)
        {:ok, new_mix_exs}

      {:error, new_line, :not_formatted} ->
        Mix.shell().info([
          :red,
          "mix_exs was not formatted. Please run `mix format` and retry, or add this line to mix.exs manually:"
        ])

        Mix.shell().info([new_line])

        {:error, :not_formatted}

      {:error, new_line, :deps_not_found} ->
        Mix.shell().info([
          :red,
          "Could not find `defp deps do` in your mix.exs. Please add this line to mix.exs manually:"
        ])

        Mix.shell().info([new_line])

        {:error, :deps_not_found}
    end
  end

  defp normalize_atom(atom, type) do
    atom =
      case atom do
        ":" <> atom -> atom
        atom -> atom
      end

    if !Regex.match?(@snake_case_regex, atom) do
      Mix.raise("Invalid #{type}: #{inspect(atom)}")
    end

    atom
  end
end
