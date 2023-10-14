vim9script

# Maintainer: Lifepillar <lifepillar@lifepillar.me>
# License: Same as Vim

const SLASH      = !exists("+shellslash") || &shellslash ? '/' : '\'
const SOUNDS_DIR = $"{resolve(expand('<sfile>:p:h:h'))}{SLASH}sounds{SLASH}"

const DEFAULT_SOUNDS: dict<list<string>> = {
  'default': ['freesound/1.wav', 'freesound/2.wav', 'freesound/3.wav'],
    "\<cr>": ['freesound/carriage1.wav'],
}

var gSounds                         = DEFAULT_SOUNDS
var gMappedKeys:       list<string> = [] # Keeps track of keys mapped by this plugin
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

def PlaySoundFor(keyOrEvent: string): string
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
  execute $'inoremap <expr> {keytrans(key)} PlaySoundFor("{key}")'
  gMappedKeys->add(key)
enddef

def MapSpecialKeys()
  for key in gSounds->keys()
    if IsSpecialKey(key) && IsUnmapped(key) && gSounds->HasSoundFor(key)
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
  var userConfig = deepcopy(get(g:, 'keysound', {}))

  gPlayingSounds    = 0
  gMaxPlayingSounds = get(g:, 'keysound_throttle', 20)
  gSounds           = deepcopy(DEFAULT_SOUNDS)->extend(userConfig, 'force')

  for soundFiles in values(gSounds)
    map(soundFiles, (_, sound) => SoundPath(sound))
  endfor

  augroup KeySound
    autocmd!
    autocmd InsertCharPre * PlaySoundFor(v:char)

    for name in keys(gSounds)
      if IsEvent(name)
        execute $"autocmd {name} * PlaySoundFor('{name}')"
      endif
    endfor
  augroup END

  MapSpecialKeys()

  echomsg '[KeySound] On'
enddef

def Disable()
  autocmd! KeySound
  augroup! KeySound

  UnmapSpecialKeys()

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

export def Debug()
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

