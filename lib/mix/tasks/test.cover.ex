defmodule Mix.Tasks.Test.Cover do
  use Mix.Task

  @moduledoc "Run tests with coverage and display results"
  @shortdoc "Run tests with coverage and display results"

  defmodule CoverageReporter do
    @moduledoc "Module for reporting test coverage"
    def report do
      html_files = Path.wildcard("cover/*.html")

      if html_files == [] do
        IO.puts("No coverage data found. Run 'mix test --cover' first.")
        exit(1)
      end

      results =
        html_files
        |> Enum.map(&parse_file/1)
        |> Enum.reject(&is_nil/1)

      print_table(results)
    end

    defp parse_file(file_path) do
      case File.read(file_path) do
        {:ok, content} ->
          module =
            file_path
            |> String.replace("cover/Elixir.", "")
            |> String.replace(".html", "")
            |> String.replace(".", "")

          coverage = extract_coverage(content)
          {module, coverage}

        {:error, _} ->
          nil
      end
    end

    defp extract_coverage(content) do
      # Count total relevant lines (lines with actual code, not comments/blanks)
      relevant_lines =
        Regex.scan(~r/<td class="source"><code>([^<]*)</, content)
        |> Enum.count(fn [_, source] ->
          source = String.trim(source)

          source != "" and
            not String.starts_with?(source, "#") and
            not String.starts_with?(source, "\"\"\"") and
            not String.ends_with?(source, "\"\"\"") and
            not String.starts_with?(source, "@moduledoc") and
            not String.starts_with?(source, "@doc")
        end)

      # Count executed lines (hits > 0)
      executed_lines = Regex.scan(~r/<td class="hits">[1-9]\d*<\/td>/, content) |> length()

      if relevant_lines > 0 do
        round(executed_lines / relevant_lines * 100)
      else
        0
      end
    end

    defp print_table(results) do
      IO.puts("\n Coverage Report")
      IO.puts("==================")

      # Print header
      IO.puts(String.pad_trailing("Module", 30) <> "Coverage")
      IO.puts(String.duplicate("-", 40))

      # Print each result
      Enum.each(results, fn {module, coverage} ->
        coverage_str = "#{coverage}%"
        # Green for >=80%, red otherwise
        color = if coverage >= 80, do: "\e[32m", else: "\e[31m"
        reset = "\e[0m"
        IO.puts(String.pad_trailing(module, 30) <> "#{color}#{coverage_str}#{reset}")
      end)

      # Print total if we have data
      if results != [] do
        total = Enum.reduce(results, 0, fn {_, cov}, acc -> acc + cov end) / length(results)
        avg_color = if total >= 80, do: "\e[32m", else: "\e[31m"
        reset = "\e[0m"
        IO.puts("")

        IO.puts(
          String.pad_trailing("Average", 30) <> "#{avg_color}#{Float.round(total, 1)}%#{reset}"
        )
      end
    end
  end

  def run(args) do
    # Run tests with coverage
    {result, _exit_code} = System.cmd("mix", ["test", "--cover"] ++ args)

    if String.contains?(result, "0 failures") do
      # Run coverage reporter
      CoverageReporter.report()
    else
      IO.puts("Tests failed, skipping coverage report")
      System.halt(1)
    end
  end
end
