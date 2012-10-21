"if exists(g:loaded_coffee_refactoring)
"  finish
"endif
"let g:loaded_coffee_refactoring = 1

function! refactoring#test()
  let aa = "aa"
  let bb = "bb"
  echo "refactoring test"
  echo aa
  echo bb
endfunction

" Synopsis:
"   Rename the selected local variable 
function! refactoring#renameLocalVariable()
  try
    let selection = common#get_visual_selection()

    " If @ at the start of selection, then abort
    if match( selection, "@" ) != -1
      throw "Selection '" . selection . "' is not a local variable"
    endif

    let name = common#get_input("Rename to: ", "No variable name given!" )
  catch
    echo v:exception
    return
  endtry

  " Find the start and end of the current block
  " TODO: tidy up if no matching 'def' found (start would be 0 atm)
  let [block_start, block_end] = common#get_range_for_block('->','Wb')

  " Rename the variable within the range of the block
  call common#gsub_all_in_range(block_start, block_end, '[^@]\<\zs'.selection.'\>\ze\([^\(]\|$\)', name)
endfunction

function! refactoring#inlineTemp()
  let original_a = @a
  normal "ayiw
  echo "1st(@a):".@a
  normal 4diw
  let original_b = @b
  normal "bd$
  echo "2nd(@b):".@a
  normal dd

  let current_line = line(".")

  let [block_start, block_end] = common#get_range_for_block('->','Wb')

  call common#gsub_all_in_range(current_line, block_end, @a, @b)

  let @a = original_a
  let @b = original_b

endfunction
