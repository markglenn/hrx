defmodule Hrx.Archive do
  @moduledoc """
  HRX file archive

  Contains the contents in memory of an HRX file.
  """

  alias Hrx.Entry

  defstruct [:entries]

  @type t :: %__MODULE__{
          entries: %{String.t() => Entry.t()}
        }

  @doc """
  Read a file from the archive

      {:ok, contents} = Hrx.Archive.read(archive, "dir/my-file.txt")
      {:error, :enoent} = Hrx.Archive.read(archive, "non-existant-file.txt")
  """
  @spec read(t(), String.t()) :: {:ok, String.t()} | {:error, :enoent}
  def read(%__MODULE__{entries: entries}, filename) do
    case entries[filename] do
      nil -> {:error, :enoent}
      contents -> {:ok, contents}
    end
  end

  def exists?(%__MODULE__{entries: entries}, path), do: Map.has_key?(entries, path)
end
