defmodule Hrx do
  @moduledoc """
  # HRX

  [Human Readable Archive](https://github.com/google/hrx) parser for Elixir.

  HRX files are useful for loading data for a test suite where creating multiple
  files is not desired.  The HRX format is easy to read and manually edit for quicker iteration.

  For more information, please see the official Github repository:
  [https://github.com/google/hrx](https://github.com/google/hrx)

  ## Quick Usage

  If we take this example HRX file called `test-suite.hrx`:

  ```hrx
  <===> test1/input.scss
  ul {
    margin-left: 1em;
    li {
      list-style-type: none;
    }
  }

  <===> test1/output.css
  ul {
    margin-left: 1em;
  }
  ul li {
    list-style-type: none;
  }
  ```

  We can load it simply with:

  ```elixir
  {:ok, archive} = Hrx.load("test-suite.hrx")

  {:ok, contents} = Hrx.Archive.read(archive, "test1/input.scss")
  {:error, :enoent} = Hrx.Archive.read(archive, "non-existant-file.txt")

  ```

  ## Installation

  If [available in Hex](https://hex.pm/docs/publish), the package can be installed
  by adding `hrx` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:hrx, "~> 0.1.0"}
    ]
  end
  ```

  """

  alias Hrx.Archive
  alias Hrx.Entry
  alias Hrx.Parser

  @doc """
  Load an HRX archive
  """
  @spec load(String.t()) :: {:error, String.t()} | {:ok, Hrx.Archive.t()}
  def load(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, boundary_length} <- get_boundary_length(contents),
         {:ok, archive, "", _, _, _} <-
           Parser.parse(contents, context: %{boundary: boundary_length}) do
      {:ok, %Archive{entries: to_entries(archive)}}
    else
      # File loading error
      {:error, reason} when is_atom(reason) ->
        {:error, :file.format_error(reason) |> to_string()}

      # Generic error from parser
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      # Parsing error
      {:error, reason, _rest, _context, _line, _byte_offset} ->
        {:error, "Error processing archive: #{reason}"}

      _ ->
        {:error, "Unknown error occurred"}
    end
  end

  defp to_entries(archive) when is_list(archive) do
    archive
    |> Enum.map(&Entry.new/1)
    |> Enum.map(&{&1.path, &1})
    |> Map.new()
  end

  defp get_boundary_length(<<"<", rest::binary>>) do
    # Look for the initial boundary so we can count the number of '='s in it.

    # Because HRX files can be nested, we have to check to make sure the
    # boundaries are exactly the same for each file.  Nested archives will have
    # a different number to distinguish them.
    case :binary.match(rest, ">") do
      {start, _} -> {:ok, start}
      _ -> {:error, "Invalid archive format. Missing initial boundary."}
    end
  end
end
