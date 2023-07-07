defmodule Letterpairs.Args do
	defstruct [
		directories: [],
		extensions:  ["txt"],
		files:       [],
		help:        false,
		verbose:     false,
		errors:      []
	]

	alias Letterpairs.Args

	def parse_args(args) do
		acc = %Letterpairs.Args{}
		parse_args(args, acc)
	end

  	defp parse_args([],                     args), do: validate(args)
   	defp parse_args(["-d", d          | t], args), do: parse_args(t, appenddir(d,  args))
   	defp parse_args(["--directory", d | t], args), do: parse_args(t, appenddir(d,  args))
   	defp parse_args(["-e", e          | t], args), do: parse_args(t, appendext(e,  args))
   	defp parse_args(["--extension", e | t], args), do: parse_args(t, appendext(e,  args))
   	defp parse_args(["-f", f          | t], args), do: parse_args(t, appendfile(f, args))
   	defp parse_args(["--file", f      | t], args), do: parse_args(t, appendfile(f, args))
   	defp parse_args(["-h"             | t], args), do: parse_args(t, %Args{args | help:    true})
   	defp parse_args(["--help"         | t], args), do: parse_args(t, %Args{args | help:    true})
   	defp parse_args(["-v"             | t], args), do: parse_args(t, %Args{args | verbose: true})
   	defp parse_args(["--verbose"      | t], args), do: parse_args(t, %Args{args | verbose: true})
    defp parse_args([h | t], args) do
      error = case h do
          <<"-", _rest::binary>> -> "unknown option #{h}"
          _                      -> "unknown action #{h}"
       end
      newerrors = args.errors ++ [error]
      parse_args(t, %Args{args | errors: newerrors})
   end

defp appenddir(directory, args) do
	 newdirs = args.directories ++ [directory]
	 %Args{args | directories: newdirs}
	end

defp appendext(extension, args) do
	 newexts = args.extensions ++ [extension]
	 %Args{args | extensions: newexts}
	end

defp appendfile(file, args) do
	 newfiles = args.files ++ [file]
	 %Args{args | files: newfiles}
	end

defp validate(args) do
	if args.files == [] and args.directories == [] do
		newerrors = args.errors ++ ["need to specify at least one file or directory to parse"]
		%{args | errors: newerrors}
	else
		args
	end
end

end
