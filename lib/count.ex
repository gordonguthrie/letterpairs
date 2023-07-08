defmodule Letterpairs.Count do

	defstruct [
		rawpairs:        %{},
		typedpairs:      %{},
		positionalpairs: %{},
		terminals:       %{},
		initials:        %{}
	]

	alias Letterpairs.Letters
	alias Letterpairs.Count

	def count(file, results, verbose) do
		if verbose do
			IO.inspect(file, label: "reading file")
		end
		case File.exists?(file) do
			true  -> read_file(file, results)
			false -> IO.inspect(file, label: "file doens't exist - skipping")
			results
		end
	end

	defp read_file(file, results) do
		case File.read(file) do
			{:ok, binary} ->
				parse_binary(binary, results)
			{:error, reason} ->
				IO.inspect({file, reason}, label: "file can't be read - skipping")
				results
		end
	end

	defp parse_binary(<<>>, result), do: result
	defp parse_binary(<<a::utf8, b::utf8, rest::binary>>, result) do
		newresult = count_pairs(make_type(a), make_type(b), result)
		parse_binary(<<b::utf8, rest::binary>>, newresult)
	end
	defp parse_binary(<<a::utf8>>, result) do
		newresult = count_pairs(make_type(a), type(<<>>), result)
		parse_binary(<<>>, newresult)
	end

	defp count_pairs(a, b, result) do
		%Count{rawpairs:        raw,
			   typedpairs:      typed,
			   positionalpairs: pos,
			   terminals:       term,
			   initials:        init} = result

		newraw   = basic_count(a.letter, b.letter, raw)
		newtyped = typed_count(a.type,   b.type, typed)
		newpos   = positional_count(a.position, b.position, pos)
		newterm  = terminal_count(a.letter, b.letter, term)
		# Note - swapped letter order
		newinit  = terminal_count(b.letter, a.letter, init)

		%Count{result | rawpairs:        newraw,
			            typedpairs:      newtyped,
			            positionalpairs: newpos,
			            terminals:       newterm,
			            initials:        newinit}
	end

	defp basic_count("", "", count), do: count
	defp basic_count(_,  "", count), do: count
	defp basic_count("",  _, count), do: count
	defp basic_count(a, b, count) do
		key = {a, b}
		case Map.has_key?(count, key) do
			true  -> v = Map.get(count, key)
					 Map.put(count, key, v + 1)
		 	false -> Map.put(count, key, 1)
		end
	end

	defp typed_count(:whitespace, :whitespace, count), do: count
	defp typed_count(_,           :whitespace, count), do: count
	defp typed_count(:whitespace,  _,          count), do: count
	defp typed_count(a, b, count) do
		key = {a, b}
		case Map.has_key?(count, key) do
			true  -> v = Map.get(count, key)
					 Map.put(count, key, v + 1)
		 	false -> Map.put(count, key, 1)
		end
	end

	defp positional_count(nil, nil, count), do: count
	defp positional_count(_,   nil, count), do: count
	defp positional_count(nil,   _, count), do: count
	defp positional_count(a, b, count) do
		key = {a, b}
		case Map.has_key?(count, key) do
			true  -> v = Map.get(count, key)
					 Map.put(count, key, v + 1)
		 	false -> Map.put(count, key, 1)
		end
	end

	defp terminal_count("", "", count), do: count
	defp terminal_count(key,  "", count) do
		case Map.has_key?(count, key) do
			true  -> v = Map.get(count, key)
					 Map.put(count, key, v + 1)
		 	false -> Map.put(count, key, 1)
		end
	end
	defp terminal_count(_, _, count), do: count


	def sortfn({_, a}, {_, b}) do
		a > b
	end

	def print(count) do
		format_and_print(count.rawpairs,        "Raw Pairs")
		format_and_print(count.typedpairs,      "Typed Pairs")
		format_and_print(count.positionalpairs, "Positional Pairs")
		format_and_print(count.terminals,       "Terminals")
		format_and_print(count.initials,        "Initials")
	end

	defp format_and_print(hash, label) do
		IO.puts(label)
		total = Enum.reduce(hash, 0, fn({_k, v}, total) -> total + v end)
		IO.inspect(total, label: "total")
		sorted = Enum.sort(hash, &sortfn/2)
		Enum.map(sorted, fn({k, v}) -> results_print(k, v, total) end)
	end

	defp results_print({a, b}, n, total) when is_atom(a) and is_atom(b) do
		perc = Float.round((n/total)*100, 1)
		IO.puts("#{a} #{b} - #{perc}%")
	end
	defp results_print({a, b}, n, total) do
		pair = a <> b
		perc = Float.round((n/total)*100, 1)
		IO.puts("#{pair} - #{perc}%")
	end
	defp results_print(a, n, total) do
		perc = Float.round((n/total)*100, 1)
		IO.puts("#{a} - #{perc}%")
	end

	defp make_type(n), do: type(List.to_string([n]))

	defp type(<<"a">>), do: %Letters{letter: <<"a">>, type: :vowel}
	defp type(<<"A">>), do: %Letters{letter: <<"a">>, type: :vowel}
	defp type(<<"b">>), do: %Letters{letter: <<"b">>, type: :plosive,     position: :labial}
	defp type(<<"B">>), do: %Letters{letter: <<"b">>, type: :plosive,     position: :labial}
	defp type(<<"c">>), do: %Letters{letter: <<"c">>, type: :stop,        position: :velar}
	defp type(<<"C">>), do: %Letters{letter: <<"c">>, type: :stop,        position: :velar}
	defp type(<<"d">>), do: %Letters{letter: <<"d">>, type: :stop,        position: :postalveolar}
	defp type(<<"D">>), do: %Letters{letter: <<"d">>, type: :stop,        position: :postalveolar}
	defp type(<<"e">>), do: %Letters{letter: <<"e">>, type: :vowel}
	defp type(<<"E">>), do: %Letters{letter: <<"e">>, type: :vowel}
	defp type(<<"f">>), do: %Letters{letter: <<"f">>, type: :fricative,   position: :labial}
	defp type(<<"F">>), do: %Letters{letter: <<"f">>, type: :fricative,   position: :labial}
	defp type(<<"g">>), do: %Letters{letter: <<"g">>, type: :stop,        position: :velar}
	defp type(<<"G">>), do: %Letters{letter: <<"g">>, type: :stop,        position: :velar}
	defp type(<<"h">>), do: %Letters{letter: <<"h">>, type: :fricative,   position: :glottal}
	defp type(<<"H">>), do: %Letters{letter: <<"h">>, type: :fricative,   position: :glottal}
	defp type(<<"i">>), do: %Letters{letter: <<"i">>, type: :vowel}
	defp type(<<"I">>), do: %Letters{letter: <<"i">>, type: :vowel}
	defp type(<<"j">>), do: %Letters{letter: <<"j">>, type: :stop,        position: :postalveolar}
	defp type(<<"J">>), do: %Letters{letter: <<"j">>, type: :stop,        position: :postalveolar}
	defp type(<<"k">>), do: %Letters{letter: <<"k">>, type: :stop,        position: :velar}
	defp type(<<"K">>), do: %Letters{letter: <<"k">>, type: :stop,        position: :velar}
	defp type(<<"l">>), do: %Letters{letter: <<"l">>, type: :approximant, position: :alveolar}
	defp type(<<"L">>), do: %Letters{letter: <<"l">>, type: :approximant, position: :alveolar}
	defp type(<<"m">>), do: %Letters{letter: <<"m">>, type: :approximant, position: :velar}
	defp type(<<"M">>), do: %Letters{letter: <<"m">>, type: :approximant, position: :velar}
	defp type(<<"n">>), do: %Letters{letter: <<"n">>, type: :nasal,       position: :alveolar}
	defp type(<<"N">>), do: %Letters{letter: <<"n">>, type: :nasal,       position: :alveolar}
	defp type(<<"o">>), do: %Letters{letter: <<"o">>, type: :vowel}
	defp type(<<"O">>), do: %Letters{letter: <<"o">>, type: :vowel}
	defp type(<<"p">>), do: %Letters{letter: <<"p">>, type: :stop,        position: :labial}
	defp type(<<"P">>), do: %Letters{letter: <<"p">>, type: :stop,        position: :labial}
	defp type(<<"q">>), do: %Letters{letter: <<"q">>, type: :stop,        position: :velar}
	defp type(<<"Q">>), do: %Letters{letter: <<"q">>, type: :stop,        position: :velar}
	defp type(<<"r">>), do: %Letters{letter: <<"r">>, type: :trill,       position: :alveolar}
	defp type(<<"R">>), do: %Letters{letter: <<"r">>, type: :trill,       position: :alveolar}
	defp type(<<"s">>), do: %Letters{letter: <<"s">>, type: :fricative,   position: :alveolar}
	defp type(<<"S">>), do: %Letters{letter: <<"s">>, type: :fricative,   position: :alveolar}
	defp type(<<"t">>), do: %Letters{letter: <<"t">>, type: :stop,        position: :alveolar}
	defp type(<<"T">>), do: %Letters{letter: <<"t">>, type: :stop,        position: :alveolar}
	defp type(<<"u">>), do: %Letters{letter: <<"u">>, type: :vowel}
	defp type(<<"U">>), do: %Letters{letter: <<"u">>, type: :vowel}
	defp type(<<"v">>), do: %Letters{letter: <<"v">>, type: :fricative,   position: :labial}
	defp type(<<"V">>), do: %Letters{letter: <<"v">>, type: :fricative,   position: :labial}
	defp type(<<"w">>), do: %Letters{letter: <<"w">>, type: :approximant, position: :velar}
	defp type(<<"W">>), do: %Letters{letter: <<"w">>, type: :approximant, position: :velar}
	defp type(<<"x">>), do: %Letters{letter: <<"x">>, type: :fricative,   position: :velar}
	defp type(<<"X">>), do: %Letters{letter: <<"x">>, type: :fricative,   position: :velar}
	defp type(<<"y">>), do: %Letters{letter: <<"y">>, type: :vowel}
	defp type(<<"Y">>), do: %Letters{letter: <<"y">>, type: :vowel}
	defp type(<<"z">>), do: %Letters{letter: <<"z">>, type: :nasal,       position: :velar}
	defp type(<<"Z">>), do: %Letters{letter: <<"z">>, type: :vowel,       position: :velar}

	defp type(<<"0">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"1">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"2">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"3">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"4">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"5">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"6">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"7">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"8">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"9">>), do: %Letters{letter: <<>>,    type: :whitespace}

	defp type(<<".">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<",">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<";">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<":">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"!">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"'">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"?">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<">">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"<">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<" ">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"&">>), do: %Letters{letter: <<>>,    type: :whitespace}
	defp type(<<"-">>), do: %Letters{letter: <<>>,    type: :whitespace}

	defp type(<<>>),     do: %Letters{letter: <<>>,   type: :whitespace}

	defp type(<<"\"">>), do: %Letters{letter: <<>>,   type: :whitespace}
	defp type(<<"\n">>), do: %Letters{letter: <<>>,   type: :whitespace}
	defp type(<<"\r">>), do: %Letters{letter: <<>>,   type: :whitespace}
	defp type(<<"\t">>), do: %Letters{letter: <<>>,   type: :whitespace}

	defp type(_x) do
		%Letters{letter: <<>>, type: :whitespace}
	end

end