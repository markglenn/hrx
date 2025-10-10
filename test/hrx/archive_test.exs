defmodule Hrx.ArchiveTest do
  use ExUnit.Case

  @base_path "vendor/hrx/example"

  describe "vendor test suite" do
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
  end

  describe "Hrx.Entry.new/1" do
    test "creates file entry with contents" do
      entry = Hrx.Entry.new({:file, {"test.txt", "content"}})

      assert %Hrx.Entry{
               path: "test.txt",
               contents: {:file, "content"}
             } = entry
    end

    test "creates file entry without contents" do
      entry = Hrx.Entry.new({:file, {"test.txt"}})

      assert %Hrx.Entry{
               path: "test.txt",
               contents: {:file, ""}
             } = entry
    end

    test "creates directory entry" do
      entry = Hrx.Entry.new({:directory, "mydir/"})

      assert %Hrx.Entry{
               path: "mydir/",
               contents: :directory
             } = entry
    end

    test "handles nested directory paths" do
      entry = Hrx.Entry.new({:directory, "parent/child/grandchild/"})

      assert %Hrx.Entry{
               path: "parent/child/grandchild/",
               contents: :directory
             } = entry
    end

    test "handles files in nested directories" do
      entry = Hrx.Entry.new({:file, {"dir1/dir2/file.txt", "nested content"}})

      assert %Hrx.Entry{
               path: "dir1/dir2/file.txt",
               contents: {:file, "nested content"}
             } = entry
    end

    test "handles files with special characters in names" do
      entry = Hrx.Entry.new({:file, {"file-name_123.test.txt", "content"}})

      assert %Hrx.Entry{
               path: "file-name_123.test.txt",
               contents: {:file, "content"}
             } = entry
    end

    test "handles empty string content" do
      entry = Hrx.Entry.new({:file, {"empty.txt", ""}})

      assert %Hrx.Entry{
               path: "empty.txt",
               contents: {:file, ""}
             } = entry
    end

    test "handles multi-line content" do
      content = "Line 1\nLine 2\nLine 3"
      entry = Hrx.Entry.new({:file, {"multi.txt", content}})

      assert %Hrx.Entry{
               path: "multi.txt",
               contents: {:file, ^content}
             } = entry
    end

    test "handles content with special characters" do
      content = "Special: !@#$%^&*()_+-=[]{}|;:',.<>?`~"
      entry = Hrx.Entry.new({:file, {"special.txt", content}})

      assert %Hrx.Entry{
               path: "special.txt",
               contents: {:file, ^content}
             } = entry
    end

    test "handles Unicode content" do
      content = "Hello 世界 🌍 Привет مرحبا"
      entry = Hrx.Entry.new({:file, {"unicode.txt", content}})

      assert %Hrx.Entry{
               path: "unicode.txt",
               contents: {:file, ^content}
             } = entry
    end
  end

  describe "Hrx.Archive operations" do
    setup do
      content = """
      <===> dir1/
      <===> dir1/file1.txt
      File 1 content
      <===> dir1/file2.txt
      File 2 content
      <===> dir2/subdir/
      <===> dir2/subdir/file3.txt
      Nested file
      <===> root.txt
      Root file
      """

      path = create_temp_file(content)
      {:ok, archive} = Hrx.load(path)

      on_exit(fn -> File.rm!(path) end)

      {:ok, archive: archive}
    end

    test "archive has correct number of entries", %{archive: archive} do
      assert map_size(archive.entries) == 6
    end

    test "archive contains all expected entries", %{archive: archive} do
      assert Hrx.Archive.exists?(archive, "dir1/")
      assert Hrx.Archive.exists?(archive, "dir1/file1.txt")
      assert Hrx.Archive.exists?(archive, "dir1/file2.txt")
      assert Hrx.Archive.exists?(archive, "dir2/subdir/")
      assert Hrx.Archive.exists?(archive, "dir2/subdir/file3.txt")
      assert Hrx.Archive.exists?(archive, "root.txt")
    end

    test "can read all files", %{archive: archive} do
      assert archive.entries["dir1/file1.txt"].contents == {:file, "File 1 content"}
      assert archive.entries["dir1/file2.txt"].contents == {:file, "File 2 content"}
      assert archive.entries["dir2/subdir/file3.txt"].contents == {:file, "Nested file"}
      # Last file in archive keeps trailing newlines per HRX spec
      assert archive.entries["root.txt"].contents == {:file, "Root file\n"}
    end

    test "directories are marked correctly", %{archive: archive} do
      assert archive.entries["dir1/"].contents == :directory
      assert archive.entries["dir2/subdir/"].contents == :directory
    end

    test "non-existent paths return false", %{archive: archive} do
      refute Hrx.Archive.exists?(archive, "nonexistent.txt")
      refute Hrx.Archive.exists?(archive, "dir3/")
      refute Hrx.Archive.exists?(archive, "dir1/nonexistent.txt")
    end
  end

  describe "Parser edge cases" do
    test "handles boundary at end of file without newline" do
      content = "<===> file.txt\nContent"
      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["file.txt"].contents == {:file, "Content"}

      File.rm!(path)
    end

    test "handles multiple consecutive newlines in content" do
      content = "<===> file.txt\nLine 1\n\n\nLine 2"
      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["file.txt"].contents == {:file, "Line 1\n\n\nLine 2"}

      File.rm!(path)
    end

    test "handles whitespace in file paths" do
      # According to HRX spec, spaces in filenames should work
      content = "<===> file with spaces.txt\nContent"
      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert Hrx.Archive.exists?(archive, "file with spaces.txt")

      File.rm!(path)
    end

    test "handles files with multiple extensions" do
      content = "<===> file.tar.gz\nArchive content"
      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["file.tar.gz"].contents == {:file, "Archive content"}

      File.rm!(path)
    end

    test "preserves exact content including special formatting" do
      content = "<===> code.py\ndef hello():\n    print('Hello')\n    return 42"
      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)

      expected = "def hello():\n    print('Hello')\n    return 42"
      assert archive.entries["code.py"].contents == {:file, expected}

      File.rm!(path)
    end
  end

  # Helper function to create temporary test files
  defp create_temp_file(content) do
    path = Path.join(System.tmp_dir!(), "hrx_archive_test_#{:rand.uniform(1_000_000)}.hrx")
    File.write!(path, content)
    path
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
