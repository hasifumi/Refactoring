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

function! refactoring#extractConstant()
  "normal NeoComplCacheDisable
  try
    let name = toupper(common#get_input("Constant name:", "No constant name given!"))
  catch
    echo v:exception
    "normal NeoComplCacheEnable
    return
  endtry

  normal! gv
  exec "normal c" . name
  exec "?^class"
  exec "normal! o" . "  " . name . " = "
  normal! $p
  "normal NeoComplCacheEnable

endfunction

function! refactoring#extractMethod() range
  try
    let name = common#get_input("Method name:", "No method name given!")
  catch
    echo v:exception
    return
  endtry

  let [block_start, block_end] = common#get_range_for_block('$->|$=>', 'Wb')
  echo "start:" . block_start . ", end:" . block_end

  let pre_selection = join( getline(block_start+1, a:first_line - 1), "\n")
  let pre_selection_variables = s:coffee_determine_variables(pre_selection)
  
  let post_selection = join( getline(a:last_line+1, block_end), "\n")
  let post_selection_variables = s:coffee_determine_variables(post_selection)
  
  let selection = common#cut_visual_selection()
  let selection_variablels = s:coffee_determine_variables(selection)

  let parameters = []
  let retvals = []

  for var in selection_variablels[1]
    call insert(parameters, var)
  endfor

  let parameters = s:sort_parameters_by_declaration(parameters)

  for var in selection_variablels[0]
    if index(post_selection_variables[1], var) != 1
      call insert(retvals, var)
    endif
  endfor

  call s:em_insert_new_method(name, selection, parameters, retvals, block_end)
endfunction

function! s:sort_parameters_by_declaration(parameters)
  if (len(a:parameters) <= 1)
    return a:parameters
  endif
  let pairs = s:build_parameters_declaration_position_pairs(a:parameters)
  call sort(pairs, "s:sort_parameters_by_declaration_position_pairs")
  return s:parameters_names_of(pairs)
endfunction

function! s:build_parameters_declaration_position_pairs(parameters)
  let cursor_position = getpos(".")
  let pairs = []

  for parm in a:parameters
    if (searchdecl(parm) == 0)
      call insert(pairs, [parm, getpos(".")])
    else
      call insert(pairs, [parm, getpos("$")])
    endif
    call setpos(",", cursor_position)
  endfor

  return pairs
endfunction


  

