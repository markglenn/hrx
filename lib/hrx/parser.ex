defmodule Hrx.Parser do
  @moduledoc """
  HRX raw file parser
  """

  import NimbleParsec

  # path-character ::= any character other than U+0000 through U+001F, U+007F DELETE, U+002F
  #                    SOLIDUS, U+003A COLON, or U+005C REVERSE SOLIDUS
  path_character =
    utf8_char([
      {:not, 0x0000..0x001F},
      {:not, 0x007F},
      {:not, 0x002F},
      {:not, 0x003A},
      {:not, 0x005C}
    ])

  # path-component ::= path-character+ // not equal to "." or ".."
  path_component =
    times(path_character, min: 1)
    |> post_traverse({:reject_special_path_component, ['.']})
    |> post_traverse({:reject_special_path_component, ['..']})

  # path ::= path-component ("/" path-component)*
  path =
    path_component
    |> repeat(concat(string("/"), path_component))
    |> wrap()
    |> map({Kernel, :to_string, []})

  # newline ::= U+000A LINE FEED
  newline = utf8_char([?\n])

  # boundary ::= "<" "="+ ">" // must exactly match the first boundary in the archive
  boundary =
    string("<")
    |> utf8_string([?=], min: 1)
    |> string(">")
    |> wrap()

  # contents ::= any sequence of characters that neither begins with boundary nor
  #              includes U+000A LINE FEED followed immediately by boundary
  contents =
    repeat_while(
      utf8_char([]),
      {:not_boundary, []}
    )
    |> wrap()
    |> map({Kernel, :to_string, []})
    |> post_traverse(:drop_initial_newline)

  # body ::= contents newline // no newline at the end of the archive (if the
  #                           // archive ends in a body, all trailing
  #                           // newlines are part of that body's contents)
  body =
    contents
    |> ignore(choice([newline, eos()]))

  # directory ::= boundary " "+ path "/" newline+
  directory =
    ignore(boundary)
    |> ignore(utf8_string([?\s], min: 1))
    |> concat(path)
    |> concat(string("/"))
    |> wrap()
    |> map({Enum, :join, []})
    |> unwrap_and_tag(:directory)
    |> ignore(times(newline, min: 1))

  # file ::= boundary " "+ path newline body?
  file =
    ignore(boundary)
    |> ignore(utf8_string([?\s], min: 1))
    |> concat(path)
    |> optional(body)
    |> wrap()
    |> map({List, :to_tuple, []})
    |> unwrap_and_tag(:file)

  # comment ::= boundary newline body
  comment =
    boundary
    |> concat(newline)
    |> concat(body)
    |> wrap()
    |> ignore()

  # entry ::= comment? (file | directory)
  entry =
    optional(comment)
    |> choice([directory, file])

  # archive ::= entry* comment?
  archive =
    repeat(entry)
    |> optional(comment)

  defparsec(:parse, archive |> eos())
  defparsec(:parse_boundary, boundary)

  defp reject_special_path_component(_rest, match, _context, _line, _offset, match),
    do: {:error, "Cannot have '#{match}' path component"}

  defp reject_special_path_component(_rest, args, context, _line, _offset, _) do
    {args, context}
  end

  defp not_boundary(<<"\n<", rest::binary>>, %{boundary: boundary} = context, _, _) do
    case :binary.match(rest, ">") do
      {^boundary, _} -> {:halt, context}
      _ -> {:cont, context}
    end
  end

  defp not_boundary(_, context, _, _), do: {:cont, context}

  defp drop_initial_newline(_, ["\n" <> args], context, _, _), do: {[args], context}
  defp drop_initial_newline(_, args, context, _, _), do: {args, context}
end
