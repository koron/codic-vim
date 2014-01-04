" vim:set sts=2 sw=2 tw=0 et:
"
" codic.vim - codic autoload file.

scriptencoding utf-8

let s:saved_cpo = &cpo
set cpo-=C

function! codic#command(...)
  if a:0 == 0
    call codic#search(expand('<cword>'))
  else
    call codic#search(a:1)
  end
endfunction

function! codic#clear()
  if exists('s:dict_naming')
    unlet s:dict_naming
  endif
  if exists('s:dict_english')
    unlet s:dict_english
  endif
endfunction

function! codic#search(word)
  if len(a:word) == 0
    echohl ErrorMsg
    echomsg 'Codic: empty word'
    echohl None
    return -1
  endif
  let dict = s:GetDictAuto(a:word)
  if len(dict) == 0
    echohl ErrorMsg
    echomsg 'Codic: dictionaries not found'
    echohl None
    return -2
  end
  let items = s:Find(dict, a:word)
  if len(items) == 0
    echohl ErrorMsg
    echomsg printf('Codic: cannot find for "%s"', a:word)
    echohl None
    return -3
  end
  let bnum = s:Show(items, a:word)
  if bnum < 0
    echohl ErrorMsg
    echomsg 'Codic: failed to open buffer'
    echohl ErrorMsg
    return -4
  endif
endfunction

function! s:ToMap(array)
  let map = {}
  for cols in a:array
    let key = get(cols, 0, '')
    if key ==# ''
      continue
    end
    let map[key] = add(get(map, key, []), cols)
  endfor
  return map
endfunction

function! s:LoadCSV(fname)
  let csv = []
  let line = ''
  for curr in readfile(a:fname, 'b')
    if &enc !=# 'utf-8'
      let curr = iconv(curr, 'utf-8', &enc)
    endif
    let line .= curr
    if curr =~# '\r$'
      continue
    endif
    let vals = map(split(line, '"\zs,\ze"'), 'v:val[1:-2]')
    call add(csv, vals)
    let line = ''
  endfor
  return csv
endfunction

function! s:LoadDict(dir, name, mapfn)
  echohl WarningMsg
  echomsg printf('Condic: loading dict:%s (first time only)', a:name)
  echohl None
  let entry = s:LoadCSV(globpath(a:dir, a:name . '-entry.csv'))
  let data = s:ToMap(s:LoadCSV(globpath(a:dir, a:name . '-translation.csv')))
  let dict = {}
  for cols in entry
    let id = get(cols, 0, '')
    if id ==# ''
      continue
    endif
    let values = get(data, id, [])
    if len(values) == 0
      continue
    endif
    let mapped_values = []
    for value in values
      let mapped = a:mapfn(cols, value)
      if len(mapped) == 0
        continue
      endif
      call add(mapped_values, mapped)
    endfor
    if len(mapped_values) == 0
      continue
    endif
    let label = cols[1]
    let dict[label] = { 'id': id, 'label': label, 'values': mapped_values }
  endfor
  redraw!
  return dict
endfunction

function! s:Map_naming(entry, trans)
  return {
        \ 'word': a:trans[3],
        \ 'desc': a:trans[4],
        \ }
endfunction

function! s:Map_english(entry, trans)
  return {
        \ 'word': a:trans[4],
        \ 'desc': a:trans[5],
        \ }
endfunction

function! s:GetDict(lang)
    if ! exists('s:dict_' . a:lang)
      let dictdir = g:codic_dictdir
      let Mapfn = function('s:Map_' . a:lang)
      let s:dict_{a:lang} = s:LoadDict(dictdir, a:lang, Mapfn)
    endif
    return s:dict_{a:lang}
endfunction

function! s:GetDictAuto(word)
  if a:word =~? '^[a-z_]\+$'
    return s:GetDict('english')
  else
    return s:GetDict('naming')
  endif
endfunction

function! s:Find(dict, word)
  let items = []
  for [ k, v ] in items(a:dict)
    let score = stridx(k, a:word)
    if score >= 0
      call add(items, { 'score': score, 'key': k, 'item': v })
    end
  endfor
  call sort(items, 's:Compare')
  return map(items[0:9], 'v:val["item"]')
endfunction

function! s:Compare(i1, i2)
  let cmp = a:i1['score'] - a:i2['score']
  if cmp != 0
    return cmp
  endif
  return len(a:i1['key']) - len(a:i2['key'])
endfunction

function! s:Show(items, word)
  " Open result buffer.
  let bnum = s:OpenScratch('=Codic Result=')
  if bnum < 0
    return bnum
  endif
  " Compose result lines.
  let lines = []
  for item in a:items
    call add(lines, printf('[%s]', item['label']))
    for value in item['values']
      let desc = ''
      if len(value['desc']) > 0
        let desc = printf(': %s', value['desc'])
      endif
      call add(lines, printf('  * %s %s', value['word'], desc))
    endfor
  endfor
  " Output to result buffer.
  silent! wincmd P
  call append(line('$'), lines)
  silent! execute '1delete'
  silent! wincmd p
  return bnum
endfunction

function! s:OpenScratch(name)
  let bnum = bufnr(a:name)
  silent! execute 'pedit ' . a:name
  if bnum < 0
    silent! wincmd P
    setlocal buftype=nofile noswapfile
    silent! wincmd p
  end
  return bufnr(a:name)
endfunction

let &cpo = s:saved_cpo
unlet s:saved_cpo
