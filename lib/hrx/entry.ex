defmodule Hrx.Entry do
  defstruct [:path, :contents]

  @type t :: %__MODULE__{
          path: String.t(),
          contents: :directory | {:file, String.t()}
        }

  @spec new({:directory, String.t()} | {:file, {String.t()} | {String.t(), String.t()}}) ::
          Hrx.Entry.t()
  def new({:file, {filename, contents}}),
    do: %__MODULE__{path: filename, contents: {:file, contents}}

  def new({:file, {filename}}), do: %__MODULE__{path: filename, contents: {:file, ""}}
  def new({:directory, directory}), do: %__MODULE__{path: directory, contents: :directory}
end
