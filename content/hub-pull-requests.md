Title: Using Hub and Fish to Turn GitHub Issues into Pull Requests
Date: 2014-09-27
Category: Scripting
Tags: Github, Hub, Zenhub, Fish
Slug: using-hub-and-fish-to-turn-github-issues-into-pull-requests
Author: Fletcher Heisler
Avatar: fletcher-heisler

## Or: How I Learned to Stop Worrying and Love ZenHub

Lately we've been making use of [ZenHub](https://www.zenhub.io/) here at TrackMaven for tracking our engineering tasks as GitHub issues move from the backlog into our current cycle, become WIP, enter QC and eventually get merged in. Although ZenHub has certainly had its growing pains (they're still in open beta), it's been great to get GitHub issues organized in one place.

One issue we've had in tracking our GitHub work, however, has been the inherent duplication between issues and pull requests. ZenHub, [HuBoard](https://huboard.com/) and other tools have no ability to filter to *only* issues or *only* pull requests - and in fact, most of the time we wouldn't want to do so, since individual issues sometimes lead to multiple separate pull requests needed to tackle them.

What we really needed was a way to *turn issues into pull requests* on demand, thus avoiding a lot of potential for duplication, noise and confusion when pull requests didn't directly reference their respective issues, commentary got split across issue/pull request, or things fell through our process when only one item of the pair had the correct WIP/QC status in ZenHub.

Enter [hub](https://github.com/github/hub). hub, available via Homebrew or as a RubyGem, has a ton of useful features and shortcuts for turbocharging your git, but the one we use most is the `pull-request` command. This uses the GitHub API's ["alternative input"](https://developer.github.com/v3/pulls/#alternative-input) to automagically **turn an existing issue into a pull request.**

The syntax can be annoyingly verbose, though, especially if you don't have upstream tracking on your git. Simple enough if you tend to work on a single project: set up an alias! Most of us here use the [fish](http://fishshell.com/) shell, where `alias` is actually just a wrapper for [function](http://ridiculousfish.com/shell/user_doc/html/commands.html#function). The easiest way to set up a `pull-request` shortcut would then be the following two functions:

```fish
    function hubpr
        hub pull-request -b [GitHubName]:master -h [GitHubName]:$argv[1] -i $argv[2]
    end

    function pr
        hubpr (git rev-parse --abbrev-ref HEAD) $argv
    end
```

You'll then need to save these functions to use them again later in other terminal sessions:

```fish
    funcsave hubpr
    funcsave pr
```

(You can also use `funced` to edit the function corresponding to the passed-in name interactively if you need to make changes.)

The `pr` function above will return the current git branch name, which gets passed into the `hubpr` function as the first argument. `hubpr` then sets the base and head branches based on the GitHub organization or username you've entered. You could of course replace `master` with `staging` or, depending on your workflow, include a separate argument to specify for determining the base branch, although this starts to undo some of the point of creating a shortcut.

The second argument, the actual issue number, is supplied when actually using the function; for instance, to make a pull request out of the newly pushed current branch `fix-everything` that will close out issue number 123, you can now do:

    pr 123

Finally, if you want to create a pull request based off of any arbitrary branch, rather than just your current branch, this simple addition to the args should do the trick: 

```fish
function hubpr
    hub pull-request -b [GitHubName]:$argv[3] -h [GitHubName]:$argv[1] -i $argv[2]
end
 
function pr
    if set -q argv[2]
       hubpr (git rev-parse --abbrev-ref HEAD) $argv[1] $argv[2]
    else
       hubpr (git rev-parse --abbrev-ref HEAD) $argv[1] master
    end
end
```

That's it! No more unnecessary issue/pull request duplication.
