vim9script

# Maintainer: Lifepillar <lifepillar@lifepillar.me>
# License: Same as Vim

const SLASH      = !exists("+shellslash") || &shellslash ? '/' : '\'
const SOUNDS_DIR = $"{resolve(expand('<sfile>:p:h:h'))}{SLASH}sounds{SLASH}"

const DEFAULT_SOUNDS: dict<list<string>> = {
  'default': ['keydown.mp3'],
    "\<cr>": ['kick.mp3'],
}

var gSounds = DEFAULT_SOUNDS
var gMappedKeys: list<string> = []  # Keeps track of keys mapped by this plugin


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

def SoundFileFor(key: string): string
  const sounds = gSounds->get(key, gSounds->get('default', []))
  const n = len(sounds)

  if n == 0
    return ''
  elseif n == 1
    return sounds[0]
  endif

  return sounds[rand() % n]
enddef

def KeyClick(key: string): string
  const soundFile = SoundFileFor(key)

  if !empty(soundFile)
    sound_playfile(soundFile)
  endif

  return key
enddef

def HasSoundFor(theKeymap: dict<list<string>>, key: string): bool
  return !empty(theKeymap->get(key, []))
enddef

def IsSpecial(key: string): bool
  return len(keytrans(key)) > 1 && key != 'default' && key != "\<space>"
enddef

def IsUnmapped(key: string): bool
  return empty(mapcheck(key, 'i'))
enddef

def MapSpecialKey(key: string)
  execute $'inoremap <expr> {keytrans(key)} KeyClick("{key}")'
  gMappedKeys->add(key)
enddef

def MapSpecialKeys()
  for key in gSounds->keys()
    if IsSpecial(key) && IsUnmapped(key) && gSounds->HasSoundFor(key)
      MapSpecialKey(key)
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
  augroup KeySound
    autocmd!
    autocmd InsertCharPre * KeyClick(v:char)
  augroup END

  var userConfig = deepcopy(get(g:, 'keysound', {}))

  gSounds = deepcopy(DEFAULT_SOUNDS)->extend(userConfig, 'force')

  for soundFiles in values(gSounds)
    map(soundFiles, (_, sound) => SoundPath(sound))
  endfor

  MapSpecialKeys()
enddef

def Disable()
  autocmd! KeySound
  augroup! KeySound

  UnmapSpecialKeys()
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

export def Debug()
  echomsg gSounds

  const mappedKeys = mapnew(gMappedKeys, (_, key) => keytrans(key))
  const config = values(
    mapnew(gSounds, (key, paths) => {
      const soundPaths = mapnew(paths, (_, p) => empty(p) ? '  none' : $'  {p}')
      return [keytrans(key)]->extend(soundPaths)
    }))

  var info =<< trim eval END
  KeySound is {exists('#KeySound') ? 'ON' : 'OFF'}

  SOUNDS DIRECTORY:
  {SOUNDS_DIR}

  MAPPED KEYS:
  {mappedKeys}

  KEYSOUND CONFIGURATION:
  END

  for item in config
    info->extend(item)
  endfor

  info->popup_dialog({
    close: 'button',
    filter: 'popup_close',
  })
enddef

