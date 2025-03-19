# GitHub Starred

✨ A GitHub CLI extension to fuzzy search your starred repositories & lists on GitHub, consume their README with your preferred tool and more. 

`gh-starred` is implemented as a `bash` program.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Help](#help)
  - [Fuzzy Search Starred Repositories](#fuzzy-search-starred-repositories)
  - [Configure Command Used to View READMEs](#configure-command-used-to-view-readmes)
  - [Preview READMEs in the Finder](#preview-readmes-in-the-finder)
  - [Configure Preview Command in Finder](#configure-previw-command-in-finder)
  - [Open the Repository in the Browser](#open-the-repository-in-the-browser)

## Installation

> [!IMPORTANT]
> This extension has hard dependencies on the `fzf` command-line fuzzy finder 
> and the JSON processing tool `jq`.
>
> Please ensure you have these installed before proceeding.
> The instructions can be found [here](https://github.com/junegunn/fzf) and [here](https://github.com/jqlang/jq)
> for `fzf` and `jq` respectively.

Install by using the GitHub CLI:
```bash
gh extension install helibom/gh-starred
```

Uninstall by using the GitHub CLI:
```bash
gh extension remove starred
```

## Usage

Make sure that you're authenticated to the GitHub CLI by first running `gh auth login` and follow the prompted instructions.

### Help

Remind yourself of the available commands by running:
```bash
gh starred -h
# or 
gh starred --help
```

### Fuzzy Search Starred Repositories

Run the extension command without arguments to start searching your starred repositories:
```bash
gh starred
```

Select a repository by pressing `Enter` to view the README of the selected repository.
By default, the README is displayed using the `less` program.

<figure>
  <img src="./assets/standard.webp" alt="Basic usage">
</figure>


### Configure Command Used to View READMEs

You can configure the command used to view a README by running:
```bash
gh starred config --view <command>
```

For example, to use [glow](https://github.com/charmbracelet/glow) as your preferred viewer, you can configure like the example below:
```bash
gh starred config --view 'glow --pager'
```

Selecting a repository will now pipe the README to your configured viewer.

<figure>
  <img src="./assets/config-view.webp" alt="Configuration of viewer">
</figure>

### Preview READMEs in the Finder

Typing `?` will preview the README of the selected repository beside the finder.

Type `_` to hide the previewer.

<figure>
  <img src="./assets/finder-preview.webp" alt="Preview README in finder">
</figure>

### Configure Preview Command in Finder

You can configure the command used to preview a README inside the finder by running:
```bash
gh starred config --preview <command>
```

For example, to use [bat](https://github.com/sharkdp/bat) as your preferred previewer, you can configure it like the example below:
```bash
gh starred config --preview 'batcat --color=always --language md'
```

> [!NOTE]
> In order for colors to work in the preview,
> your command must preserve ANSI color codes when redirected, hence the `--color=always` flag.

<figure>
  <img src="./assets/config-preview.webp" alt="Configure previewer">
</figure>

### Open the Repository in the Browser

Pressing `Ctrl-T` inside the finder will open the selected repository in your default browser.

<figure>
  <img src="./assets/finder-browser.webp" alt="Configure previewer">
</figure>
