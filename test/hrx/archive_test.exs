defmodule Hrx.ArchiveTest do
  use ExUnit.Case

  @base_path "vendor/hrx/example"

  alias Hrx.Archive

  test "all the passing examples" do
    @base_path
    |> Path.join("*.hrx")
    |> Path.wildcard()
    |> Enum.map(&Path.basename/1)
    |> Enum.each(&assert_archive/1)
  end

  defp assert_archive(filename) do
    assert {:ok, archive} =
             @base_path
             |> Path.join(filename)
             |> Archive.load()

    result_path =
      @base_path
      |> Path.join(["extracted/", Path.basename(filename, ".hrx")])

    archive.entries
    |> Enum.each(&assert_entry(&1, result_path))
  end

  defp assert_entry({filename, %{contents: {:file, contents}}}, result_path) do
    path = Path.join([result_path, filename])

    assert {:ok, file_contents} = File.read(path)

    assert file_contents == contents, "Expected file #{filename} to match contents"
  end

  defp assert_entry({directory, %{contents: :directory}}, result_path) do
    path = Path.join([result_path, directory])

    assert File.exists?(path)
  end
end
