---
title: "Moving From Vim to Emacs"
date: 2021-08-14T10:29:09-04:00
Updated: 2021-08-14T10:29:09-04:00
categories: Thoughts
tags:
    - Vim
    - Emacs
    - Text Editor
---

YouTube has been pushing me a lot Emacs related contents. This is weird since mostly I watch Vim videos only. But probably this is also a great opportunity to try Emacs again.

I have tried Emacs half year ago. I looked a lot Elisp programming fundamentals and tried a few Emacs configurations from others including Doom Emacs. However, it didn't last long since I found that I didn't have enough time to configure this Emacs setup as good as the [Vim setup][my-vim-config] that I was using. Also using other's configurations makes things become complicated for me. They have too many packages included and I don't know what they are whether they are useful for me or not.

After watching a bunch of Emacs videos I decided to pick it up this time, with vanilla Emacs starting from scratch. The reason why I make my mind this time is because I found Emacs can perfectly and elegantly solve some problems that pain my ass:

- More convenient package management.
- High quality packages.
- Easier file management in shell environment (Dired)
- No third party dependencies like Node.js and Python. The two major plugs that I'm using in Vim are Coc and Leaderf. They require Node.js and Python to work. Since Elisp is power enough, Emacs can handle this easily by itself.
- Server-client architecture. I can even replace Tmux with Emacs now. NeoVim has the similar concept but it cannot match what Emacs has.
- Graphical interface in X mode. This makes Emacs be able to display rich contents.
- Org mode. It looks great to organize to-do list and take notes without switching to other applications.
- Evil mode. No need to worry about missing Vim's features.
- Magit. Looks way better and nicer than fugitive.
- Elisp Right. Elisp is fun 😉.

The migration is going slowly. Right now my main setup is still Vim + Tmux. There is a little curve learning from vanilla edition of Emacs, but It's not a big deal compared with the first time when I started learning Vim 🙂.

In the end, dont't give me wrong. Vim and Emacs both are great text editor. For me, Vim is more like a spirit, a concept. Once you've learned its high-efficiency key maps, you can use it everywhere. Even though I switch to Emacs I still use Vim mode together with Emacs' powerful extendability. Why not?  

[my-vim-config]: https://github.com/peromage/rice.vim
