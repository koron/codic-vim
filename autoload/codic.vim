" vim:set sts=2 sw=2 tw=0 et:
"
" codic.vim - codic autoload file.

scriptencoding utf-8

let s:saved_cpo = &cpo
set cpo-=C

let s:HTTP = vital#codic#import('Web.HTTP')
let s:JSON = vital#codic#import('Web.JSON')

function! codic#command(...)
  if a:0 == 0
    call s:Search(expand('<cword>'))
  else
    call s:Search(a:1)
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

function! codic#complete(arglead, cmdline, curpos)
  let r = codic#search(a:arglead, 50)
  if type(r) == 0
    return []
  endif
  return map(r, 'v:val["label"]')
endfunction

" search from codic.
"   word  - keyword to search
"   limit - limit number of candidates (0:unlimitted)
function! codic#search(word, limit)
  if len(a:word) == 0
    return -1
  endif
  if exists('g:codic_token')
    let items = s:GetDictWebAuto(a:word, a:limit)
  else
    let items = s:GetDictAuto(a:word, a:limit)
  endif
  return items
endfunction

function! s:EchoError(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction

function! s:Search(word)
  let r = codic#search(a:word, 10)
  if type(r) == 0
    if r == -1
      call s:EchoError('Codic: empty word')
    elseif r == -2
      call s:EchoError('Codic: dictionaries not found')
    elseif r == -3
      call s:EchoError(printf('Codic: cannot find for "%s"', a:word))
    else
      call s:EchoError(printf('Codic: unknown error %d', r))
    endif
    return r
  endif
  let bnum = s:Show(r, a:word)
  if bnum < 0
    echohl ErrorMsg
    echomsg 'Codic: failed to open buffer'
    echohl None
    return -4
  endif
  return 0
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
  echomsg printf('Codic: loading dict:%s (first time only)', a:name)
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

function! s:GetDictAuto(word,limit)
  if a:word =~? '^[a-z_]\+$'
    let dict s:GetDict('english')
  else
    let dict s:GetDict('naming')
  endif
  if len(dict) == 0
    return -2
  end
  let items = s:Find(dict, a:word, a:limit)
  if len(items) == 0
    return -3
  end
  return items
endfunction

function! s:GetDictWebAuto(word,limit)
  if a:word =~? '^[a-z_]\+$'
    let dict = s:GetDictWebCEDLookup(a:word, a:limit)
    if len(dict) == 0
      return -2
    end
    let items = []
    let entry = { 'label': a:word, 'values': []}
    for item in dict
      let value = {
            \ 'word' : item.title,
            \ 'desc' : item.digest,
            \}
      call add(entry.values, value)
    endfor
    call add(items, entry)
    if len(items) == 0
      return -3
    endif
    return items
  else
    let dict = s:GetDictWebEngine(a:word, a:limit)
    if len(dict) == 0
      return -2
    end
    let items = []
    for item in dict
      for word in item.words
        if word.successful
          let entry = { 'label': word.text, 'values': []}
          for candidate in word.candidates
            let value = {
                  \ 'word' : candidate.text,
                  \ 'desc' : word.text . ' translate to ' . word.translated_text,
                  \}
            call add(entry.values, value)
          endfor
          call add(items, entry)
        endif
      endfor
    endfor
    if len(items) == 0
      return -3
    endif
    if a:limit != 0
      let items = items[0:(a:limit - 1)]
    endif
    return items
  endif
endfunction

" [
"   {'digest': 'ベクトル、一次元配列、ベクター形式の', 'id': 43970, 'title': 'vector'},
"   {'digest': 'ベークター化', 'id': 50405, 'title': 'vectorization'},
"   {'digest': 'ベクター化する', 'id': 50404, 'title': 'vectorize'}
" ]
function! s:GetDictWebCEDLookup(word, limit)
  let url = 'https://api.codic.jp/v1/ced/lookup.json'
  let limit = (a:limit == 0) ? 9999 : a:limit
  let param = {
        \ 'query' : a:word,
        \ 'count' : limit,
        \}
  let res = s:HTTP.request('GET', url, {
        \ 'param'      : param,
        \ 'token'      : g:codic_token,
        \ 'authMethod' : 'oauth2',
        \})
  let dict = []
  if res.success
    let dict = s:JSON.decode(res.content)
  endif
  return dict
endfunction

" [
"   {
"     'successful': 1,
"     'text': 'ベクタ',
"     'translated_text': 'vector',
"     'words': [{'candidates': [{'text': 'vector'}], 'successful': 1, 'text': 'ベクタ', 'translated_text': 'vector'}]
"   }
" ]
function! s:GetDictWebEngine(word, limit)
  let url = 'https://api.codic.jp/v1/engine/translate.json'
  let param = {
        \ 'text' : a:word,
        \}
  let res = s:HTTP.request('GET', url, {
        \ 'param'      : param,
        \ 'token'      : g:codic_token,
        \ 'authMethod' : 'oauth2',
        \})
  let dict = []
  if res.success
    let dict = s:JSON.decode(res.content)
  endif
  return dict
endfunction

function! s:Find(dict, word, limit)
  let lower_word = tolower(a:word)
  let items = []
  for [ k, v ] in items(a:dict)
    let score = stridx(k, lower_word)
    if score >= 0
      call add(items, { 'score': score, 'key': k, 'item': v })
    end
  endfor
  call sort(items, 's:Compare')
  return map(items[0:(a:limit - 1)], 'v:val["item"]')
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
  silent! execute 'pedit ' . escape(a:name, ' \')
  if bnum < 0
    silent! wincmd P
    setlocal buftype=nofile noswapfile modifiable
    silent! wincmd p
  end
  return bufnr(a:name)
endfunction

let &cpo = s:saved_cpo
unlet s:saved_cpo
