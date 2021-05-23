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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hrx](https://hexdocs.pm/hrx).

