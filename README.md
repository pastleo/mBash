# MinttyFPS
Run scoop-installed-msys **Mintty** **F**rom **P**ower**S**hell, with one-off command support and shortcut adding / removing

## Installation

First, go get `scoop` from [http://scoop.sh/](http://scoop.sh/)  

#### Stable version:

```
scoop install https://gist.githubusercontent.com/chgu82837/7a37ec7c6a972beff149/raw/minttyFPS.json
```

#### Current master version:

```
scoop install https://gist.githubusercontent.com/chgu82837/7a37ec7c6a972beff149/raw/minttyFPSD.json
```

## Usage

### Run a bash at the current working directory

```
mintty
```

Example:  

![01](https://media.giphy.com/media/26tPd8IiIbVcs5Uu4/giphy.gif)

### Run a one-off command using bash in mintty

```
mintty <bin> [parameters]
```

Example:  

![02](https://media.giphy.com/media/26tPuymluC7ceuqXu/giphy.gif)

### Add/Remove shortcut for mintty command

```
mintty --add|-a <name> <bin> [parameters]
mintty --rmove|-r <name>
```

Example 1: make ssh using mintty to run  

![03](https://media.giphy.com/media/d2ZkvgWicLNigKJy/giphy.gif)

Example 2: make an alias (shortcut) to run a command in mintty  

![04](https://media.giphy.com/media/26tPoMhwgVJinxDqM/giphy.gif)
