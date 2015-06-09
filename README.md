# Yesod from scratch with Nix on Mac OS X

The easiest way to get started on Mac, is to install Haskell Platform.  And that's where most Haskell beginners start with if they are Mac users.

If that's where you are and you would like to switch to using Nix, start by uninstalling Haskell Platform.  A small shell script yet would help you uninstall Haskell Platform cleanly - <a href="https://github.com/hskoans/HaskellUtilities/blob/master/uninstall-haskell-platform.sh">https://github.com/hskoans/HaskellUtilities/blob/master/uninstall-haskell-platform.sh</a>.

It is possible to use both the ghc installed via Haskell Platform and the ghc installed Nix but that requires a lot of work to make sure you get your PATH right; or all hell will break loose.  I have a simple `use_haskell` shell function in my dotfiles that facility switching between Haskell Platform and Nix-installed ghc/cabal tool chain but I do not recommend that you use it.

It's far too easy to get it wrong juggling the PATHs between Haskell Platform binaries and Nix-env installed binaries in your user space.

My recommendation is that you switch to using Nix completely and revel in the power of hermetic builds.

## Using nixpkgs unstable

```
cd ~
git clone git@github.com/NixOS/nixpkgs
cd ~/.nix-defexpr
rm -rf channels
ln -s ~/nixpkgs nixpkgs
export NIX_PATH=nixpkgs=$HOME/nixpkgs:$NIX_PATH  # place this in .bash_profile or .zprofile to persist it
```

## Using binaries instead of compiling every damn thing

```
sudo mkdir /etc/nix
sudo vim /etc/nix/nix.conf
```

In `nix.conf`, add in:

```
binary-caches = http://zalora-public-nix-cache.s3-website-ap-southeast-1.amazonaws.com/ http://cache.nixos.org/ http://hydra.nixos.org/
```

This saves us a ton of time thanks to zalora's Mac OS X 10.10's binaries.  Note that it does not work with Mac OS X 10.9.

## Base requirements

Here are some basic utilities we need to get started:

```
nix-env -iA nixpkgs.haskellPackages.ghc
nix-env -iA nixpkgs.haskellPackages.cabal-install
nix-env -iA nixpkgs.haskellPackages.cabal2nix
nix-env -iA nixpkgs.haskellPackages.yesod-bin
```

Now, we can scaffold our Yesod project

```
cd ~/work  # This is just a directory where I keep most of my projects
mkdir Yesod1
cd Yesod1
yesod init --bare
```

This needed if we are running cabal for the first time otherwise, it's optional.

```
cabal update
```

We will also need to specify this for Mac OS X

```
export NIX_CFLAGS_COMPILE="-idirafter /usr/include"
export NIX_CFLAGS_LINK="-L/usr/lib"
```

as Nix does not know the location of C libraries like Math.h


Let's install and get cracking.

```
// cabal sandbox
cabal sandbox init

// happy and alex are required
cabal install happy alex

// Now the actual dependencies required by Yesod
cabal install -j --enable-tests --max-backjumps=-1 --reorder-goals

// Start our yesod app
yesod devel
```

## Bumped into some errors?

```
readlink: illegal option -- f
usage: readlink [-n] [file ...]
```

This is because on linux, the `readline` utility accepts an option `-f`.  But Mac OS X/BSD's readline does not have this behavior.

To solve this problem, we can install `greadlink` which is available in `coreutils` via brew or macports and then make the `readlink` program symlink to `greadlink`.

I use Macports and my `/opt/local/bin` path takes precedence over `/usr/bin`.

So, after installing `coreutils`, I simply run:

```
sudo ln -s /opt/local/bin/greadlink /opt/local/bin/readlink
source ~/.zprofile   # or .bash_profile if you use bash, or just restart your shell
```

Now, `yesod devel` will not result in the `readlink: illegal option --f` errors

A better solution is to use the readlinke in `coreutils` that comes with Nix. :-)

```
$ nix-env -qaP coreutils
nixpkgs.coreutils  coreutils-8.23
$ nix-env -iA nixpkgs.coreutils
```

Since `$HOME/.nix-profile/bin` PATH takes precendence over `/opt/local/bin` (Macports) and takes precedence over the built-in Mac OS X PATHs `/user/local/bin`,`/usr/bin` and `/bin`, we should be good to go.

## Let's have some fun with Haskell/Yesod

### cabal2nix for shell.nix

`cabal2nix`'s `--shell` flag when-specified creates a nix expression file that is intended to be loaded as an entry point when we run the `nix-shell` command.

```
cd ~/work/Yesod1   # That's where our yesod-scaffolded source code is
cabal2nix --shell . > shell.nix
```

We can jump into our Nix shell environment to work on our Yesod1 project by simply running `nix-shell`.

### cabal2nix for default.nix

The `default.nix` file, on-the-other-hand, makes our `Yesod1` project a package that can be called in Nix.  It is not loaded by `shell.nix` in this case.

```
cabal2nix . > default.nix
```

We can now edit `~/.nixpkgs/config.nix`:

```
{
  packageOverrides = super: let self = super.pkgs; in
  {
    yesod1 = self.haskellPackages.callPackage ../work/Yesod1 {};
  };
}
```

When we do this, we make it possible to run `nix-env -iA yesod1`.
