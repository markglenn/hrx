defmodule Hrx.Archive do
  alias Hrx.Parser
  alias Hrx.Entry

  defstruct [:entries]

  @type t :: %__MODULE__{
          entries: %{String.t() => Entry.t()}
        }

  @spec load(String.t()) :: {:error, String.t()} | {:ok, Hrx.Archive.t()}
  def load(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, boundary_length} <- get_boundary_length(contents),
         {:ok, archive, "", _, _, _} <-
           Parser.parse(contents, context: %{boundary: boundary_length}) do
      {:ok, %__MODULE__{entries: to_entries(archive)}}
    else
      {:error, reason} when is_atom(reason) ->
        {:error, :file.format_error(reason) |> to_string()}

      {:error, reason, _rest, _context, _line, _byte_offset} ->
        {:error, "Error processing archive: #{reason}"}

      _ ->
        {:error, "Unknown error occurred"}
    end
  end

  defp to_entries(archive) do
    archive
    |> Enum.map(&Entry.new/1)
    |> Enum.map(&{&1.path, &1})
    |> Map.new()
  end

  defp get_boundary_length(<<"<", rest::binary>>) do
    case :binary.match(rest, ">") do
      {start, _} -> {:ok, start}
      _ -> {:error, "Initial boundary not found"}
    end
  end
end
