Title: Setting up Vim for Djangular Development
Date: 2015-12-29
Category: development
Tags: javascript, python, vim
Slug: vim-and-djangular
Author: Josh Finnie
Avatar: josh-finnie

I thought I'd write something different for a change and let everyone into a little secrete of mine; [Vim](http://www.vim.org/) is AWESOME! Of course, that's not really the secrete, but it is the truth. This blog post will go over the details of my Vim set up that turned vanilla awesome Vim into a super-charged, double-awesome workhorse for me and my work at TrackMaven. It is no surprise that the majority of my day-to-day work involves working with both [Python](https://www.python.org/) and [Javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript); we use both of them almost equally here. And it took me a while to set up Vim just right to handle Python, Javascript and [Coffeescript](http://coffeescript.org/) as first class citizens.

## Setting up Vim

The first thing we want to do is make sure that we have the ability to add what we need to add it Vim to make it super-charged. There are many package managers out there for Vim: [Pathogen](https://github.com/tpope/vim-pathogen), [Vundle](https://github.com/VundleVim/Vundle.vim), [NeoBundle](https://github.com/Shougo/neobundle.vim), [Plug](https://github.com/junegunn/vim-plug), and many more (though these are the four most popular and I would highly suggest using one of these). For this example I will be using Vundle; I have had a lot of success with Vundle, and I really enjoy the ability to put my plugins in my `.vimrc` file for source control.

To install Vundle, you should follow the steps here: [Vundle Quick Start](https://github.com/VundleVim/Vundle.vim#quick-start) After that, we need to add some boilerplate to our `.vimrc` file and we are ready to start adding plugins to Vim!

```
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
" Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub
" Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
" Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
```

Once the boilerplate `.vimrc` is completed, we can then move on to installing some packages that will aid us in our journey towards making Vim work awesomely with Djangular.

## Setting Up Python

First we will start with Python as I feel it is the easiest of the three to set up correctly. When discussing packages in this post, we are going to do so on two levels. The first level is the absolute basic amount of plugins I would recommend. The second level is the level where you start to take Vim away from a text editor and into the world of IDE. This line however is a grey one, and arguments can be made that even my basic level of plugins takes Vim away from what it should be. Take my suggestions, and this argument for that matter, with a grain of salt. 


