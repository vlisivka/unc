#!/bin/bash
# Notebook compiler for Rust.
# License: GPL3+
# Author: Volodymyr M. Lisivka <vlisivka@gmail.com>
. import.sh strict log arguments

CODE_LANG="rust"

INPUT_FILE=""
INPUT_FILE_EXTENSION=".$CODE_LANG.md"

OUTPUT_FILE=""
OUTPUT_FILE_EXTENSION=".md"

TMP_PROJECT_DIR=""

# Alternative characters for variable enclosure:
# ⁅⁆ ❨❩ ❪❫ ❬❭ ❮❯ ❰❱ ❲❳ ❴❵ ⟦⟧ ⟨⟩ ⟪⟫ ⟬⟭ ⟮⟯ ⦃⦄ ⦇⦈ ⦉⦊ ⦑⦒ ⦗⦘ ⧼⧽ ⸨⸩
START_OF_VAR="«"
END_OF_VAR="»"


print_file_header() {
  printf "%s" '
fn main() {

'
}

print_file_footer() {
  printf "%s" '
}
'
}

print_start_of_print() {
  printf "%s" '  print!("{}", "'
}

print_end_of_print() {
  printf "%s\n" '");'
}

# Escape special variables in text, so text can be used in string.
escape() {
  local -n __var_name="$1"

  # Replace all \ by \\
  __var_name="${__var_name//\\/\\\\}"

  # Replace all " by \"
  __var_name="${__var_name//\"/\\\"}"
}

escape_line() {
  local line="$1"

  escape line

  printf "%s\n" "$line"'\n\'
}

print_line_with_variables() {
  local line="$1"

  printf "%s\n" 'println!("'"$line"'");'
}

print_output_header() {
  local output_header="$1"

  escape output_header

  printf "%s\n" 'println!("{}", "'"$output_header"'");'
}

print_output_block_header() {
  printf "%s\n" 'println!("\n```");'
}

print_output_block_footer() {
  printf "%s\n" 'println!("\n```\n");'
}

convert_line_with_embedded_variables() {
  local line="$1"

  local result=""

  # Replace variables in Markdown with print statements
  while [[ "$line" =~ ^([^$START_OF_VAR]+)"$START_OF_VAR"([^$END_OF_VAR]+)"$END_OF_VAR" ]]
  do
    local prefix="${BASH_REMATCH[1]}"
    local match_length="${#BASH_REMATCH[0]}"
    local var="${BASH_REMATCH[2]}"

    escape prefix

    result="$result$prefix{$var}"
    line="${line:$match_length}"
  done

  # Append remainder
  escape line
  result="$result$line"

  print_end_of_print
  print_line_with_variables "$result"
  print_start_of_print
}

convert_markdown_to_rust() {
  local md_file="${1:?ERROR: Markdown file is required.}"
  [ -f "$md_file" ] || { error "Markdown file doesn't exist."; return 1; }

  # Read whole file into array.
  local lines=( )
  mapfile -t lines <"$md_file" || panic "Can't read lines from \"$md_file\" file into array."

  print_start_of_print

  # Walk file line by line and look for "```rust" block header or "${var}" variables.
  # If a line begins with "!", then skip it.
  local i line
  for ((i=0; i < ${#lines[@]}; i++))
  do
    line="${lines[i]}"

    if [[ "$line" == '```'"$CODE_LANG"* ]]
    then
      # Block header found

      # Look for options
      local skip_block="no" hidden_block="no" raw_output="no" output_header=""
      ! [[ "$line" =~ [^a-zA-Z0-9_]"skip"([^a-zA-Z0-9_]|$) ]] || skip_block="yes"
      ! [[ "$line" =~ [^a-zA-Z0-9_]"hide"([^a-zA-Z0-9_]|$) ]] || hidden_block="yes"
      ! [[ "$line" =~ [^a-zA-Z0-9_]"raw_output"([^a-zA-Z0-9_]|$) ]] || raw_output="yes"
      ! [[ "$line" =~ [^a-zA-Z0-9_]"no_output"([^a-zA-Z0-9_]|$) ]] || raw_output="yes"
      ! [[ "$line" =~ [^a-zA-Z0-9_]"output_header=\""([^\"]*)"\"" ]] || output_header="${BASH_REMATCH[1]}"

      # Scan text until end of block is found, while printing original text
      local start_of_block="$i" end_of_block=""
      for ((; i < ${#lines[@]}; i++))
      do
        line="${lines[i]}"

        # Remove options from block header
        if [[ "$i" == "$start_of_block" ]]; then line='```rust'; fi

        if [[ "$hidden_block" == "no" ]] ; then
          escape_line "$line" || { error "Can't escape line of Rust code from Markdown for use in Rust."; return 1; }
        fi

        if [[ "$line" == '```' ]]
        then
          end_of_block="$i"
          break
        fi
      done
      [ -n "$end_of_block" ] || { error "End of code block starting at line #$((start_of_block+1)) is not found in file \"$INPUT_FILE\"."; return 1; }

      # Now, print same block, but in raw, to execute as part of the program
      if [[ "$skip_block" == "no" ]]
      then
        print_end_of_print

        if [[ -n "$output_header" ]] ; then
          print_output_header "$output_header"
        fi

        if [[ "$raw_output" == "no" ]] ; then
          print_output_block_header
        fi

        for ((j=start_of_block+1; j < end_of_block; j++))
        do
          # Print raw code as is
          printf "%s\n" "${lines[j]}"
        done

        if [[ "$raw_output" == "no" ]] ; then
          print_output_block_footer
        fi

        print_start_of_print
      fi

    elif [[ "$line" == *"$START_OF_VAR"*"$END_OF_VAR"* ]]
    then

      # A variable is found in text, convert the text to print statement with variables
      convert_line_with_embedded_variables "$line" || { error "Can't convert line with embedded variables to Rust: \"$line\"."; return 1; }

    else

      # Just escape and print line to Rust source
      escape_line "$line" || { error "Can't escape line of text in Markdown for use in Rust."; return 1; }

    fi
  done

  print_end_of_print
}

main() {

  # For input file "foo.rust.md", output file will be "foo.md"
  [[ "$INPUT_FILE" == *"$INPUT_FILE_EXTENSION" ]] || panic "Input file name \"$INPUT_FILE\" must end with \"$INPUT_FILE_EXTENSION\"."
  [ -n "$OUTPUT_FILE" ] || OUTPUT_FILE="${INPUT_FILE%$INPUT_FILE_EXTENSION}$OUTPUT_FILE_EXTENSION"
  [[ "$OUTPUT_FILE" != "$INPUT_FILE" ]] || panic "Input file name and output file name are equal. Refuse to overwrite input file."

  # If temporary directory for temporary  project is not set by user, then create it
  if [ -z "$TMP_PROJECT_DIR" ]; then
    TMP_PROJECT_DIR="$(mktemp --directory)"
    [ -d "$TMP_PROJECT_DIR" ] || panic "Temporary directory \"$TMP_PROJECT_DIR\" for temporary Cargo project is not created. Is mktemp installed?"
  else
    rm -rf "$TMP_PROJECT_DIR"/* || panic "Can't cleanup temporary directory \"$TMP_PROJECT_DIR\"."
    mkdir -p "$TMP_PROJECT_DIR" || panic "Can't create temporary directory \"$TMP_PROJECT_DIR\"."
  fi

  # Name of Rust file in temporary project
  local rust_file="$TMP_PROJECT_DIR/markdownpage/src/main.rs"

  # Generate temporary project
  pushd "$TMP_PROJECT_DIR" || panic "Can't change workind directory to \"$TMP_PROJECT_DIR\"."
  cargo init --bin "markdownpage" || panic "Can't create temporary project \"markdownpage\" in \"TMP_PROJECT_DIR\" directory."
  popd

  # Generate Rust file
  print_file_header > "$rust_file" || panic "Can't overwrite \"$rust_file\" file with new header for Rust program."
  convert_markdown_to_rust "$INPUT_FILE" >> "$rust_file" || panic "Can't convert Markdown file \"$INPUT_FILE\" into Rust file \"$rust_file\"."
  print_file_footer >> "$rust_file" || panic "Can't append footer for Rust program."

  # Compile and execute program
  ( cd "$TMP_PROJECT_DIR/markdownpage" ; cargo build ) || panic "Can't build \"markdownpage\" project in \"$TMP_PROJECT_DIR/markdownpage\" directory."
  ( cd "$TMP_PROJECT_DIR/markdownpage" ; cargo run ) > "$OUTPUT_FILE" || panic "Can't run \"markdownpage\" project in \"$TMP_PROJECT_DIR/markdownpage\" directory."

  # Cleanup
  rm -rf "$TMP_PROJECT_DIR"/* || panic "Can't cleanup temporary directory."
}

arguments::parse \
   "-i|--input-file)INPUT_FILE;String,Required" \
   "-o|--output-file)OUTPUT_FILE;String" \
   "-t|--tmpdir|--temporary-directory)TMP_PROJECT_DIR;String" \
   -- \
   "${@:+$@}" || exit $?

main "${ARGUMENTS[@]}" || exit $?

exit 0

#>> ## NAME
#>>
#>>> `unc-rust` - notebook compiler for Rust
#>>
#>> ## SYNOPSIS
#>>
#>> `unc-rust [OPTIONS] -i INPUT_FILE`
#>>
#>> ## OPTIONS
#>>
#>> *  -i|--input-file INPUT_FILE - input file to parse. Must end with
#>>   ".rust.md".
#>>
#>> *  -o|--output-file OUTPUT_FILE - output file to parse. Default
#>>   value: name of input file with ".rust.md" replaced by ".md".
#>>
#>> *  -t|--tmpdir|--temporary-directory TMP_PROJECT_DIR - temporary
#>>   direcory to use. By default, mktemp is used to create temporary
#>>   directory.
#>>
#> ## DESCRIPTION
#>
#> `unc-rust` will convert Markdown file with embedded Rust code into Rust
#> program, which will be executed to print Markdown file. Idea is similar
#> to PHP pages.
#>
#> Embedded code must start with "```rust [options]" and end with "```".
#>
#> Embedded variables must start with "«" and end with "»".
#>
