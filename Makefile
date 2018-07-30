default::
	@esy install
	@esy build

b build::
	@esy b dune build

fmt:
	@find bin rrundep rrunlib -name '*.ml' -or -name '*.mli' \
		| xargs -n1 esy ocamlformat --inplace
