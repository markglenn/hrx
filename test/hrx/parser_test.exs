defmodule Hrx.ParserTest do
  use ExUnit.Case

  @base_path "vendor/hrx/example"

  alias Hrx.Parser

  test "comment only", do: match_file("comment-only.hrx", "")
  test "comments", do: match_file("comments.hrx", "")
  test "empty file", do: match_file("empty-file.hrx", "")
  test "directory", do: match_file("directory.hrx", "")

  defp match_file(filename, match) do
    @base_path
    |> Path.join(filename)
    |> File.read!()
    |> match_parse(match)
  end

  defp match_parse(document, match) do
    assert {:ok, ^match, "", _, _, _} = Parser.parse(document)
  end
end
