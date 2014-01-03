" vim:set sts=2 sw=2 tw=0 et:
"
" codic.vim - codic plugin.

scriptencoding utf-8

if !exists('g:codic_dictdir')
  let g:codic_dictdir = globpath(expand('<sfile>:p:h:h'), 'dict')
endif

command! -nargs=? Codic call codic#command(<f-args>)
