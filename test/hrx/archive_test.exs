defmodule Hrx.ArchiveTest do
  use ExUnit.Case

  @base_path "vendor/hrx/example"

  test "all the passing examples" do
    @base_path
    |> Path.join("*.hrx")
    |> Path.wildcard()
    |> Enum.map(&Path.basename/1)
    |> Enum.each(&assert_archive/1)
  end

  test "invalid directory contents" do
    assert {:error, _} =
             @base_path
             |> Path.join("invalid/directory-contents.hrx")
             |> Hrx.load()
  end

  defp assert_archive(filename) do
    assert {:ok, archive} =
             @base_path
             |> Path.join(filename)
             |> Hrx.load()

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
