if exists('g:loaded_cmake-format') || &cp || !executable('cmake-format')
	finish
endif
let g:loaded_cmake_format = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:cmake_format_fmt_on_save")
	let g:cmake_format_fmt_on_save = 0
endif

if !exists('g:cmake_format_cmd')
	let g:cmake_format_cmd = 'cmake-format'
endif

" Options
if !exists('g:cmake_format_extra_args')
	let g:cmake_format_extra_args = ''
endif

" Ref: 'rhysd/vim-clang-format' /autoload/clang_format.vim
function! s:has_vimproc() abort
	if !exists('s:exists_vimproc')
		try
			silent call vimproc#version()
			let s:exists_vimproc = 1
		catch
			let s:exists_vimproc = 0
		endtry
	endif
	return s:exists_vimproc
endfunction
function! s:success(result) abort
	let exit_success = (s:has_vimproc() ? vimproc#get_last_status() : v:shell_error) == 0
	return exit_success
endfunction

function! s:error_message(result) abort
	echohl ErrorMsg
	echomsg 'cmake_format has failed to format.'
	echomsg ''
	echohl None
endfunction

let g:cnt = 0
function! s:cmake_format(current_args)
	let l:extra_args = g:cmake_format_extra_args
	let l:cmake_format_cmd = g:cmake_format_cmd
	let l:cmake_format_opts = ' ' . a:current_args . ' ' . l:extra_args
	if a:current_args != ''
		let l:cmake_format_opts = a:current_args
	endif
	let tempfilepath=tempname()
	call writefile(getline(1, '$'), tempfilepath)
	let l:cmake_format_output = system(l:cmake_format_cmd . ' ' . l:cmake_format_opts . ' ' . tempfilepath)
	if s:success(l:cmake_format_output)
		let pos_save = a:0 >= 1 ? a:1 : getpos('.')
		let winview = winsaveview()
		let splitted = split(l:cmake_format_output, '\n')
		silent! undojoin
		if line('$') > len(splitted)
			execute len(splitted) .',$delete' '_'
		endif
		call setline(1, splitted)
		call winrestview(winview)
		call setpos('.', pos_save)
	else
		call s:error_message(l:cmake_format_output)
	endif
endfunction

augroup cmake_format
	autocmd!
	if get(g:, "cmake_format_fmt_on_save", 1)
		autocmd BufWritePre *.cmake cmake_format
		autocmd BufWritePre CMakeLists.txt cmake_format
		autocmd FileType cmake autocmd BufWritePre <buffer> cmake_format
	endif
augroup END

command! -bar -complete=custom,s:cmake_formatSwitches -nargs=? CmakeFormat :call <SID>cmake_format(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
