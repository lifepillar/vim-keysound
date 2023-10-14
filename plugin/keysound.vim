vim9script

# Maintainer: Lifepillar <lifepillar@lifepillar.me>
# License: Same as Vim

import autoload '../autoload/keysound.vim' as keysound

if exists("g:loaded_keysound")
  finish
endif

g:loaded_keysound = true

command -bar -nargs=0 KeySoundOn     keysound.On()
command -bar -nargs=0 KeySoundOff    keysound.Off()
command -bar -nargs=0 KeySoundToggle keysound.Toggle()
command -bar -nargs=0 KeySoundDebug  keysound.Debug()

