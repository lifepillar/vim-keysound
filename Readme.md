# KeySound: Turn Vim into a Typewriter

                                /`*_
                                /    `-_
                     _.,  _.   /        `-_
                 _,-` __`-_ `-/            `-_
              ,-  .,~`  /  `-/               .`
             :_ -`     "    /`-@             /
                      /`\  ;    `-_         /
                   |-`.. `-\  |    `-_     / `-_
                _-`  `_.`\  `-_ |;\   @-_ / `-_/
               -  .__.,,;___o  `-_|      /`-__-_
              - 1`-_ .~--` _~` o   `-_   ;   `   -
            .`Q W 2 `-_ `,`. /- - o   `-_\  `     `
           - A S  E  3 `-_  . / .|   _ ..`-_;     :
        _-` Z X  D F R T 4`-_  ;  ;   `_ `_-`.-_,`
     .-`--_     C   G   Y  5 `-_ i    _-`    ;
    :  `-_//`-_   V  H J U I 6  `-_.-`       *
    -_    `-_  `-_    B N K L O 7 -          :
      `-_    `-_  `-_    M . ; P .`      es  ;
         `-_    `-_  `-_     ,  -           _`
            `-_    `-_ /     -`         _-`
               `-_    `-_/-_`        _-`
                  `-_    `-.      _-`
                     `-_   .   .-`
                        `-_:_-`  Dedicated to the memory of Bram

KeySound adds typewriter sounds to Vim in Insert mode. It can also associate
sounds to any auto-command event. It requires Vim 9.0 or later compiled with
`+sound`. Features:

- customize sounds;
- define distinct sounds for distinct keys or events;
- define multiple sounds for the same key or event (randomization);
- disable sounds for specific keys.

*Happy writing!*


### Call for sounds!

Do you have high quality typewriter sounds that can be legally distributed?
Please open a pull request!


## Installation

    cd ~/.vim
    git clone https://github.com/lifepillar/vim-keysound.git pack/<dir>/start/keysound

where `<dir>` is a name of your choice.

Enable sounds with `:KeySoundOn` and turn them off with `:KeySoundOff`. Toggle
sounds with `:KeySoundToggle`.

Sounds for each key press can be configured by defining `g:keysound` in your
`vimrc`. See `:help keysound.txt` for the details.


## Credits

See CREDITS in `doc/keysound.txt`.
