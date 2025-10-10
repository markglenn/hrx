defmodule HrxTest do
  use ExUnit.Case
  doctest Hrx

  describe "load/1" do
    test "loads a simple HRX file with one entry" do
      content = """
      <===> file.txt
      Hello, World!
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert Map.has_key?(archive.entries, "file.txt")
      assert archive.entries["file.txt"].contents == {:file, "Hello, World!\n"}

      File.rm!(path)
    end

    test "loads an HRX file with multiple entries" do
      content = """
      <===> file1.txt
      First file

      <===> file2.txt
      Second file

      <===> dir/file3.txt
      Third file
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert map_size(archive.entries) == 3
      assert archive.entries["file1.txt"].contents == {:file, "First file\n"}
      assert archive.entries["file2.txt"].contents == {:file, "Second file\n"}
      assert archive.entries["dir/file3.txt"].contents == {:file, "Third file\n"}

      File.rm!(path)
    end

    test "loads an HRX file with a directory entry" do
      content = """
      <===> mydir/

      <===> mydir/file.txt
      File in directory
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["mydir/"].contents == :directory
      assert archive.entries["mydir/file.txt"].contents == {:file, "File in directory\n"}

      File.rm!(path)
    end

    test "loads an HRX file with empty file" do
      content = """
      <===> empty.txt
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["empty.txt"].contents == {:file, ""}

      File.rm!(path)
    end

    test "loads an HRX file with comments" do
      content = """
      <===>
      This is a comment
      It can span multiple lines

      <===> file.txt
      Content
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert map_size(archive.entries) == 1
      assert archive.entries["file.txt"].contents == {:file, "Content\n"}

      File.rm!(path)
    end

    test "loads an HRX file with different boundary lengths" do
      content = """
      <=====> file.txt
      Content with longer boundary
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["file.txt"].contents == {:file, "Content with longer boundary\n"}

      File.rm!(path)
    end

    test "handles files with newlines in content" do
      content = """
      <===> file.txt
      Line 1
      Line 2
      Line 3
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["file.txt"].contents == {:file, "Line 1\nLine 2\nLine 3\n"}

      File.rm!(path)
    end

    test "handles files with trailing newlines" do
      content = """
      <===> file.txt
      Content


      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert archive.entries["file.txt"].contents == {:file, "Content\n\n\n"}

      File.rm!(path)
    end

    test "rejects invalid path component '.'" do
      content = """
      <===> .
      Invalid
      """

      path = create_temp_file(content)

      assert {:error, error_msg} = Hrx.load(path)
      assert error_msg =~ "Cannot have '.' path component"

      File.rm!(path)
    end

    test "rejects invalid path component '..'" do
      content = """
      <===> ..
      Invalid
      """

      path = create_temp_file(content)

      assert {:error, error_msg} = Hrx.load(path)
      assert error_msg =~ "Cannot have '..' path component"

      File.rm!(path)
    end

    test "rejects path with '..' component in the middle" do
      content = """
      <===> dir/../file.txt
      Invalid
      """

      path = create_temp_file(content)

      assert {:error, error_msg} = Hrx.load(path)
      assert error_msg =~ "Cannot have '..' path component"

      File.rm!(path)
    end

    test "returns error for non-existent file" do
      assert {:error, error_msg} = Hrx.load("/non/existent/path.hrx")
      assert is_binary(error_msg)
    end

    test "returns error for file without boundary" do
      content = "This is not a valid HRX file"
      path = create_temp_file(content)

      assert {:error, error_msg} = Hrx.load(path)
      # The error is raised from get_boundary_length which expects a '<' at the start
      assert is_binary(error_msg)

      File.rm!(path)
    end

    test "handles multiple files with same directory prefix" do
      content = """
      <===> dir/file1.txt
      First

      <===> dir/file2.txt
      Second

      <===> dir/subdir/file3.txt
      Third
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert map_size(archive.entries) == 3

      File.rm!(path)
    end

    test "handles empty archive" do
      content = """
      <===>
      Just a comment, no files
      """

      path = create_temp_file(content)

      assert {:ok, archive} = Hrx.load(path)
      assert map_size(archive.entries) == 0

      File.rm!(path)
    end
  end

  describe "Hrx.Archive.read/2" do
    test "reads existing file from archive" do
      content = """
      <===> test.txt
      Test content
      """

      path = create_temp_file(content)
      {:ok, archive} = Hrx.load(path)

      entry = archive.entries["test.txt"]
      assert {:file, "Test content\n"} = entry.contents

      File.rm!(path)
    end

    test "returns error for non-existent file" do
      content = """
      <===> test.txt
      Test content
      """

      path = create_temp_file(content)
      {:ok, archive} = Hrx.load(path)

      assert {:error, :enoent} = Hrx.Archive.read(archive, "nonexistent.txt")

      File.rm!(path)
    end
  end

  describe "Hrx.Archive.exists?/2" do
    test "returns true for existing file" do
      content = """
      <===> test.txt
      Test content
      """

      path = create_temp_file(content)
      {:ok, archive} = Hrx.load(path)

      assert Hrx.Archive.exists?(archive, "test.txt")

      File.rm!(path)
    end

    test "returns false for non-existent file" do
      content = """
      <===> test.txt
      Test content
      """

      path = create_temp_file(content)
      {:ok, archive} = Hrx.load(path)

      refute Hrx.Archive.exists?(archive, "nonexistent.txt")

      File.rm!(path)
    end

    test "returns true for existing directory" do
      content = """
      <===> dir/
      """

      path = create_temp_file(content)
      {:ok, archive} = Hrx.load(path)

      assert Hrx.Archive.exists?(archive, "dir/")

      File.rm!(path)
    end
  end

  # Helper function to create temporary test files
  defp create_temp_file(content) do
    path = Path.join(System.tmp_dir!(), "hrx_test_#{:rand.uniform(1_000_000)}.hrx")
    File.write!(path, content)
    path
  end
end
