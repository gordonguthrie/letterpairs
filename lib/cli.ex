defmodule Letterpairs.CLI do
	@moduledoc """
		Letter Pairs reads texts and counts and categorises letter pairs

		Options:
		-d --directory adds a directory to scan
		               (can be added many times)

		-e --extension adds an extension to scan the directory for
		               bare extension only (no .s)
		               (txt already added)
		               (can be added many times)

		-f --file      adds a path and file (with extension) to be scanned
		               (can be added many times)

		-h --help      prints this message

		-v --verbose   run in verbose mode
	"""

	alias Letterpairs.Args
	alias Letterpairs.Count

	def main([]) do
		IO.puts(@moduledoc)
	end
	def main(args) do
		parsedargs =  Args.parse_args(args)
		if parsedargs.verbose == true do
			IO.inspect(parsedargs, label: "running letter pairs with")
		end
		run(parsedargs, %Letterpairs.Count{})
	end

	defp run(parsedargs, _count) when parsedargs.help do
		IO.puts(@moduledoc)
	end
	defp run(parsedargs, _count) when parsedargs.errors != [] do
		print_errors(parsedargs)
		IO.puts("run ./letterpairs -h for help")
	end
	defp run(parsedargs, count) when parsedargs.files != []  do
		[h | t] = parsedargs.files
		newcount = Count.count(h, count)
		run(%Args{parsedargs | files: t}, newcount)
	end
	defp run(parsedargs, count) when parsedargs.directories != []  do
		[h | t] = parsedargs.directories
		newcount = walk_directory(h, parsedargs.extensions, count)
		run(%Args{parsedargs | directories: t}, newcount)
	end
	defp run(_parsedargs, count) do
		Count.print(count)
	end

	defp walk_directory(dir, extensions, count) do
		files = Path.wildcard(make_wildcard(dir, extensions))
		walk(files, count)
	end

	defp walk([],      count), do: count
	defp walk([h | t], count), do: walk(t, Count.count(h, count))

	defp make_wildcard(dir, extensions) do
		ext = Enum.join(extensions, ",")
		wildcard = Enum.join(["*.{", ext,"}"])
		Path.join(dir, wildcard)
	end

	defp print_errors(parsedargs) do
      IO.puts("script did not run because of the following errors:")
      for x <- parsedargs.errors, do: IO.puts(x)
      IO.puts("")
    end

end