vim9script

# Maintainer: Lifepillar <lifepillar@lifepillar.me>
# License: Same as Vim

const SLASH      = !exists("+shellslash") || &shellslash ? '/' : '\'
const SOUNDS_DIR = $"{resolve(expand('<sfile>:p:h:h'))}{SLASH}sounds{SLASH}"

const DEFAULT_SOUNDS: dict<list<string>> = {
  'default': ['keyany.wav'],
    "\<cr>": ['keyenter.wav'],
}

var gEnabled:          bool         = false
var gSounds                         = DEFAULT_SOUNDS
var gMappedKeys:       list<string> = [] # Keeps track of keys mapped by this plugin
var gConflictingKeys:  list<string> = [] # Keeps track of already mapped keys
var gPlayingSounds:    number            # Number of simultaneously playing sounds
var gMaxPlayingSounds: number            # Maximum number of simultaneously playing sounds


def SoundPath(soundFile: string): string
  if empty(soundFile)
    return ''
  endif

  const fullPath = simplify(SOUNDS_DIR .. soundFile)
  const n = len(SOUNDS_DIR)

  if slice(fullPath, 0, n) != SOUNDS_DIR
    echoerr $'[KeySound] Invalid sound path: {soundFile} (outside {SOUNDS_DIR}).'
  endif

  return fullPath
enddef

def SoundFileFor(keyOrEvent: string): string
  const sounds = gSounds->get(keyOrEvent, gSounds->get('default', []))
  const n = len(sounds)

  if n == 0
    return ''
  elseif n == 1
    return sounds[0]
  endif

  return sounds[rand() % n]
enddef

def PlaySound(keyOrEvent: string): string
  const soundFile = SoundFileFor(keyOrEvent)

  if !empty(soundFile) && gPlayingSounds < gMaxPlayingSounds
    gPlayingSounds += 1

    if sound_playfile(soundFile, (id, _) => {
      gPlayingSounds -= 1
    }) == 0
    gPlayingSounds -= 1
    endif
  endif

  return keyOrEvent
enddef

def HasSoundFor(theKeymap: dict<list<string>>, key: string): bool
  return !empty(theKeymap->get(key, []))
enddef

def IsEvent(name: string): bool
  return exists($'##{name}')
enddef

def IsSpecialKey(key: string): bool
  return len(keytrans(key)) > 1 && key != 'default' && key != "\<space>" && !IsEvent(key)
enddef

def IsUnmapped(key: string): bool
  return empty(mapcheck(keytrans(key), 'i'))
enddef

def MapSpecialKey(key: string)
  execute $'inoremap <expr> {keytrans(key)} PlaySound("{key}")'
  gMappedKeys->add(key)
enddef

def MapSpecialKeys()
  for key in gSounds->keys()
    if IsSpecialKey(key) && gSounds->HasSoundFor(key)
      if IsUnmapped(key)
        MapSpecialKey(key)
      else
        gConflictingKeys->add(key)
      endif
    endif
  endfor
enddef

def UnmapSpecialKeys()
  for key in gMappedKeys
    if !IsUnmapped(key)
      execute 'iunmap' keytrans(key)
    endif
  endfor

  gMappedKeys = []
enddef

def Enable()
  var userConfig = deepcopy(get(g:, 'keysound', {}))

  gPlayingSounds    = 0
  gMaxPlayingSounds = get(g:, 'keysound_throttle', 20)
  gSounds           = deepcopy(DEFAULT_SOUNDS)->extend(userConfig, 'force')
  gConflictingKeys  = []

  for soundFiles in values(gSounds)
    map(soundFiles, (_, sound) => SoundPath(sound))
  endfor

  augroup KeySound
    autocmd!
    autocmd InsertCharPre * PlaySound(v:char)
  augroup END

  augroup KeySoundEvent
    autocmd!

    for name in keys(gSounds)
      if IsEvent(name)
        execute $"autocmd {name} * PlaySound('{name}')"
      endif
    endfor
  augroup END

  MapSpecialKeys()
  gEnabled = true

  echomsg '[KeySound] On'
enddef

def Disable()
  if get(g:, 'keysound_toggle_event_sounds', true)
    autocmd! KeySoundEvent
    augroup! KeySoundEvent
  endif

  autocmd! KeySound
  augroup! KeySound

  UnmapSpecialKeys()

  gEnabled = false
  echomsg '[KeySound] Off'
enddef

export def On()
  if !exists('#KeySound')
    Enable()
  endif
enddef

export def Off()
  if exists('#KeySound')
    Disable()
  endif
enddef

export def Toggle()
  if exists('#KeySound')
    Disable()
  else
    Enable()
  endif
enddef

export def PlaySoundFor(key: string, returnKey: bool = true): string
  if gEnabled
    PlaySound(key)
  endif

  if returnKey
    return key
  endif

  return ''
enddef

export def Debug()
  const mappedKeys  = mapnew(gMappedKeys, (_, key) => keytrans(key))
  const conflicting = mapnew(gConflictingKeys, (_, key) => keytrans(key))
  const config      = values(
    mapnew(gSounds, (key, paths) => {
      const soundPaths = mapnew(paths, (_, p) => {
        if empty(p)
          return '  No sound'
        elseif !gEnabled || filereadable(p)
          return $'  {p}'
        else
          return $'  [MISSING] {p}'
        endif
      })

      return [keytrans(key)]->extend(soundPaths)
    }))
  const status = gEnabled ? 'ON' : 'OFF'
  const events = get(g:, 'keysound_toggle_event_sounds', true) ? status : 'ALWAYS ON'
  const throttle = get(g:, 'keysound_throttle', 20)

  var info =<< trim eval END
       ╭───────────────────╮
       │ COPY TO CLIPBOARD │
       ╰━━━━━━━━━━━━━━━━━━━╯

    ~~~ STATUS ~~~
    KeySound is {status}
    Events sounds are {events}
    Max number of simultaneous sounds is {throttle}

    ~~~ SOUNDS DIRECTORY ~~~
    {SOUNDS_DIR}

  END

  if gEnabled
    var mappedText =<< trim eval END
      ~~~ KEYS MAPPED BY KEYSOUND ~~~
      {empty(mappedKeys) ? 'None' : join(mappedKeys, ' ')}

    END
    info->extend(mappedText)
  endif

  if gEnabled && !empty(conflicting)
    var conflictText =<< trim eval END
      ~~~ CONFLICTING MAPPINGS ~~~
      {join(conflicting, ' ')}

    END
    info->extend(conflictText)

  endif

  info->add('~~~ CONFIGURATION ~~~')

  for item in config
    info->extend(item)
  endfor

  def Filter(winid: number, key: string): bool
    if key == "\<cr>" || key == "\<esc>"
      popup_close(winid)
      return true

    elseif key == "\<LeftMouse>"
      const mousepos = getmousepos()

      if mousepos.winid == winid &&
          mousepos.winrow > 1 && mousepos.winrow < 5 &&
          mousepos.wincol > 2 && mousepos.wincol < 24
        @* = join(getbufline(winbufnr(winid), 5, '$'), "\n")
        echomsg "[KeySound] Info copied to system clipboard!"

        return true
      endif
    endif

    return false
  enddef

  info->popup_dialog({
    title:      '  KeySound Information  ',
    drag:       1,
    close:      'button',
    filter:     Filter,
    filtermode: 'n',
  })
enddef
