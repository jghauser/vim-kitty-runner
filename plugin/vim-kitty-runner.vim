function! s:InitVariable(var, value)
  if !exists(a:var)
    let escaped_value = substitute(a:value, "'", "''", "g")
    silent exec 'let ' . a:var . ' = ' . "'" . escaped_value . "'"
    return 1
  endif
  return 0
endfunction

function! s:SendKittyCommand(command)
  let prefixed_command = g:AsyncCommand . "kitty @ --to=" . g:KittyPort . " " . a:command
  silent exec prefixed_command
endfunction

function! s:OpenNewKitty()
  let prefixed_command = g:AsyncCommand . "kitty -o allow_remote_control=yes --listen-on=" . g:KittyPort . " --title=" . s:runner_name . "&"
  redraw
  silent exec prefixed_command
endfunction

function! s:RunCommand()
  call inputsave()
  let s:command = input('Command to run: ')
  call inputrestore()
  let s:wholecommand = join([s:run_cmd, shellescape(s:command, 1), ""])

  if exists("s:runner_open")
    call s:SendKittyCommand(s:wholecommand)
  else
    let s:runner_open = 1
    call s:SendKittyCommand("new-window --title " . s:runner_name . " " . g:KittyWinArgs)
    call s:SendKittyCommand(s:wholecommand)
  endif
endfunction

function! s:RunLastCommand()
  if exists("s:runner_open")
    call s:SendKittyCommand(s:wholecommand)
  endif
endfunction

function! s:ClearRunner()
  if exists("s:runner_open")
    call s:SendKittyCommand(s:run_cmd . " ")
  endif
endfunction

function! s:KillRunner()
  if exists("s:runner_open")
    call s:SendKittyCommand(s:kill_cmd)
    unlet s:runner_open
  endif
endfunction

function! s:SendLines()
  let s:command = substitute(getline("."), '\\', '\\\\', "g")
  let s:command = s:command . "\r"
  let s:wholecommand = join([s:run_cmd, shellescape(s:command, 1), ""])
  if exists("s:runner_open")
    call s:SendKittyCommand(s:wholecommand)
  else
    let s:runner_open = 1
    call s:OpenNewKitty()
    " call s:SendKittyCommand("new-window --title " . s:runner_name . " " . g:KittyWinArgs)
    call s:SendKittyCommand(s:wholecommand)
  endif
endfunction

function! s:CheckAsyncAvailable()
  if exists(":Start!")
    let g:AsyncCommand = "Start! "
  elseif exists(":AsyncRun")
    let g:AsyncCommand = "AsyncRun "
  else
    let g:AsyncCommand = '!'
  endif
endfunction

function! s:InitializeVariables()
  let uuid = system("uuidgen|sed 's/.*/&/'")[:-2]
  let s:runner_name = "vim-cmd_" . uuid
  " let s:run_cmd = "send-text --match=title:" . s:runner_name
  " let s:kill_cmd = "close-window --match=title:" . s:runner_name
  let s:run_cmd = "send-text --match=title:" . s:runner_name
  let s:kill_cmd = "close-window --match=title:" . s:runner_name
  call s:InitVariable("g:KittyUseMaps", 1)
  let s:KittyPort = "unix:/tmp/kitty" . str2nr(matchstr(reltimestr(reltime()), '\v\.@<=\d+')[1:])
  call s:InitVariable("g:KittyPort", s:KittyPort)
  call s:InitVariable("g:KittyWinArgs", "--keep-focus --cwd=" . $PWD)
  call s:CheckAsyncAvailable()
endfunction

function! s:DefineCommands()
  command! KittyRunCommand call s:RunCommand()
  command! -range KittySendLines  <line1>,<line2>call s:SendLines()
  command! KittyRunCommandAgain call s:RunLastCommand()
  command! KittyClearRunner call s:ClearRunner()
  command! KittyKillRunner call s:KillRunner()
endfunction

function! s:DefineKeymaps()
  if g:KittyUseMaps
    nmap <Leader>tr :KittyRunCommand<CR>
    xmap <Leader>ts :KittySendLines<CR>
    nmap <Leader>tc :KittyClearRunner<CR>
    nmap <Leader>tk :KittyKillRunner<CR>
    nmap <Leader>tl :KittyRunCommandAgain<CR>
  endif
endfunction

call s:InitializeVariables()
call s:DefineCommands()
call s:DefineKeymaps()
