# Git Pivotal Tracker Integration
`pivotal-integration` provides a set of additional Git commands to help developers when working with [Pivotal Tracker][pivotal-tracker]. It is based on and extended from [git-pivotal-tracker-integration](https://github.com/nebhale/git-pivotal-tracker-integration) by Ben Hale.

[pivotal-tracker]: http://www.pivotaltracker.com


## Installation
`pivotal-integration` requires at least **Ruby 1.8.7** and **Git 1.8.2.1** in order to run.  It is tested against Rubies _1.8.7_, _1.9.3_, and _2.0.0_.

This fork is not in the rubygems repository! To install it, do the following:

```plain
$ git clone https://github.com/demands/pivotal-integration
$ cd pivotal-integration
$ gem build pivotal-integration.gemspec
$ gem install pivotal-integration-1.6.0.2.gem
```

Eventually the install process will make a bit more sense.


## Usage
`pivotal-integration` is intended to be a very lightweight tool, meaning that it won't affect your day to day workflow very much.  To be more specific, it is intended to automate branch creation and destruction as well as story state changes, but will not affect when you commit, when development branches are pushed to origin, etc.  The typical workflow looks something like the following:

```plain
$ pivotal start       # Creates branch and starts story
$ git commit ...
$ git commit ...      # Your existing development process
$ git commit ...
$ pivotal finish      # Merges and destroys branch, pushes to origin, and finishes story
```


## Configuration

### Git Client
In order to use `pivotal-integration`, two Git client configuration properties must be set.  If these properties have not been set, you will be prompted for them and your Git configuration will be updated.

| Name | Description
| ---- | -----------
| `pivotal.api-token` | Your Pivotal Tracker API Token.  This can be found in [your profile][profile] and should be set globally.
| `pivotal.project-id` | The Pivotal Tracker project id for the repository your are working in.  This can be found in the project's URL and should be set.

[profile]: https://www.pivotaltracker.com/profile


### Git Server
In order to take advantage of automatic issue completion, the [Pivotal Tracker Source Code Integration][integration] must be enabled.  If you are using GitHub, this integration is easy to enable by navgating to your project's 'Service Hooks' settings and configuring it with the proper credentials.

[integration]: https://www.pivotaltracker.com/help/integrations?version=v3#scm


## Commands

### `pivotal start [new] [ type | story-id ]`
This command starts a story by creating a Git branch and changing the story's state to `started`.  This command can be run in four ways.  First it can be run specifying the id of the story that you want to start.

```plain
$ pivotal start 12345678
```

The second way to run the command is by specifying the type of story that you would like to start.  In this case it will then offer you the first five stories (based on the backlog's order) of that type to choose from.

```plain
$ pivotal start feature

1. Lorem ipsum dolor sit amet, consectetur adipiscing elit
2. Pellentesque sit amet ante eu tortor rutrum pharetra
3. Ut at purus dolor, vel ultricies metus
4. Duis egestas elit et leo ultrices non fringilla ante facilisis
5. Ut ut nunc neque, quis auctor mauris
Choose story to start:
```

The third way to run the command lets you create a new story straight from the command line. You can specify which type of story you'd like to create in the command, or you will be prompted to choose. The story name and estimate is also specified. The new story will then be assigned and started.

```plain
$ pivotal start new
1. Feature
2. Bug
3. Chore
4. Release
What type of story do you want to create: 
Provide a name for the new story:
Choose an estimation for this story [0, 1, 2, 3, enter for none]: 
```

Finally the command can be run without specifying anything.  In this case, it will then offer the first five stories (based on the backlog's order) of any type to choose from.

```plain
$ pivotal start

1. FEATURE Donec convallis leo mi, dictum ornare sem
2. CHORE   Sed et magna lectus, sed auctor purus
3. FEATURE In a nunc et enim tincidunt interdum vitae et risus
4. FEATURE Fusce facilisis varius lorem, at tristique sem faucibus in
5. BUG     Donec iaculis ante neque, ut tempus augue
Choose story to start:
```

Once a story has been selected by one of the methods, the command then prompts for the name of the branch to create.

```plain
$ pivotal start 12345678
        Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes
  Description: Ut consequat sapien ut erat volutpat egestas. Integer venenatis lacinia facilisis.

Enter branch name (12345678-<branch-name>):
```

The value entered here will be prepended with the story id such that the branch name is `<story-id>-<branch-name>`.  This branch is then created and checked out.

If it doesn't exist already, a `prepare-commit-msg` commit hook is added to your repository.  This commit hook augments the existing commit messsage pattern by appending the story id to the message automatically.

```plain

[#12345678]
# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
# On branch 12345678-lorem-ipsum
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#	new file:   dolor.txt
#
```

### `pivotal finish [--no-complete] [--pull-request] [--no-merge]`
This command finishes a story. There are two workflows that can be used for finishing (pull requests and merging).

#### Pull Request Workflow
The pull request workflow can be accessed by specifying the `--pull-request` option, or by setting `pivotal.finish-mode` to `pull_request` in your git config. When using the PR workflow, when finishing a story, the branch will be pushed to the `origin` remote, and PR will be started (either launched in a web browser, or through the console using [hub](https://github.com/github/hub)). The behaviour can be specified by setting `pivotal.pull-request-editor` to `web` or `hub` in your git config.

In both cases, the story will also be updated to mark its status as Finished.

```plain
$ pivotal finish --pull-request
Pushing to origin... OK
Changing state to finished
```

#### Merge Workflow
This command finishes a story by merging and cleaning up its branch and then pushing the changes to a remote server.  This command can be run in two ways.  First it can be run without the `--no-complete` option.

```plain
$ pivotal finish
Checking for trivial merge from 12345678-lorem-ipsum to master... OK
Merging 12345678-lorem-ipsum to master... OK
Deleting 12345678-lorem-ipsum... OK
Pushing to origin... OK
```

The command checks that it will be able to do a trivial merge from the development branch to the target branch before it does anything.  The check has the following constraints

1.  The local repository must be up to date with the remote repository (e.g. `origin`)
2.  The local merge target branch (e.g. `master`) must be up to date with the remote merge target branch (e.g. `origin/master`)
3.  The common ancestor (i.e. the branch point) of the development branch (e.g. `12345678-lorem-ipsum`) must be tip of the local merge target branch (e.g. `master`)

If all of these conditions are met, the development branch will be merged into the target branch with a message of:

```plain
Merge 12345678-lorem-ipsum to master

[Completes #12345678]
```

The second way is with the `--no-complete` option specified. In this case `finish` performs the same actions except the `Completes`... statement in the commit message will be supressed.

```plain
Merge 12345678-lorem-ipsum to master

[#12345678]
```

After merging, the development branch is deleted and the changes are pushed to the remote repository.

### `pivotal release [story-id]`
This command creates a release for a story.  It does this by updating the version string in the project and creating a tag.  This command can be run in two ways.  First it can be run specifying the release that you want to create.

```plain
$ pivotal release 12345678
```
The other way the command can be run without specifying anything.  In this case, it will select the first release story (based on the backlog's order).

```plain
$ pivotal release
      Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes
```

Once a story has been selected by one of the two methods, the command then prompts for the release version and next development version.

```plain
$ pivotal release
      Title: Lorem ipsum dolor sit amet, consectetur adipiscing elitattributes

Enter release version (current: 1.0.0.BUILD-SNAPSHOT): 1.0.0.M1
Enter next development version (current: 1.0.0.BUILD-SNAPSHOT): 1.1.0.BUILD-SNAPSHOT
Creating tag v1.0.0.M1... OK
Pushing to origin... OK
```

Once these have been entered, the version string for the current project is updated to the release version and a tag is created.  Then the version string for the current project is updated to the next development version and a new commit along the original branch is created.  Finally the tag and changes are pushed to the remote sever.

Version update is currently supported for the following kinds of projects.  If you do not see a project type that you would like supported, please open an issue or submit a pull request.

### `pivotal new [type] [name]` 
This command lets you create a new story in Pivotal Tracker directly from the command line. The story type and name can be provided as command line options or from prompts. Creating a story in this way adds it to the Icebox, and does not assign or start the story (contrasted to `pivotal start new`).

```plain
$ pivotal new feature "Create a blog"
```

```plain
pivotal new
1. Feature
2. Bug
3. Chore
4. Release
What type of story do you want to create: 
Provide a name for the new story: 
```

### `pivotal info`
This command gives you an output of info from the current story (including description, notes, etc.).

```plain
$ pivotal info
         ID: 123456
    Project: My Project
      Title: Create a blog
       Type: Feature
      State: Started
   Estimate: 3
     Note 1: How many posts do we want to limit the blog to?
```

### `pivotal estimate [points]`
This command lets you set or change the estimate for the current story. This command can be run in two ways. First it can be run by specifying the score you want to assign.

```plain
$ pivotal estimate 3
```

The second way is to run the command with specifying anything. In this case, the current estimate will be shown, as well as all the possible values (as set up for the project in Pivotal Tracker). In this mode, you can also choose to remove the estimate by leaving the score prompt blank.

```plain
$ pivotal estimate
Story is currently estimated 3.
Choose an estimation for this story [0, 1, 2, 3, enter for none]:
```

### `pivotal switch ID`
This command lets you switch the active Pivotal Tracker story to a different one.

```plain
$ pivotal switch 12345678
```

### `pivotal assign [username]`
This command assigns current story to another member of Pivotal Tracker project.  This command can be run in two ways.  First it can be run with specific username of project's member. If username consists of more than one world use braces as in example.

```plain
$ pivotal assign 'Mark Twain'
```

The other way the command can be run without specifying anything.  In this case, you will be able to choose from all project members.

```plain
$ pivotal assign

1. Mark Twain
2. Edgar Alan Poe
Choose an user from above list:
```

### `pivotal label [mode] label1 ... labeln`
This command manages story labels, there are four modes you can use:
* add - appends new labels to story
* once - appends new labels to story and removes it's occurences from every other story in project
* remove - removes labels from story
* list - lists labels attached to current story

```plain
$ pivotal label list
```

You have to specify mode and at least on label if you are using add, once or remove modes.

```plain
$ pivotal label add on_qa
```

### `pivotal mark [state]`
This command marks current story with specified state. You can add desired state as follows:

```plain
$ pivotal mark finished
```

The other way the command can be run without specifying anything.  In this case, you will be able to choose from all possible states.

```plain
$ pivotal mark

1. unstarted
2. started
3. finished
4. delivered
5. rejected
6. accepted
Choose story state from above list:
```

### `pivotal comment TEXT`
This command allows you to add a comment (note) to the current story. The comment text must be given with the command.

```plain
$ pivotal comment "Good idea!"
```

### `pivotal open [project]`
This command lets you open the current story or project in a web browser (this functionality is provided by [launchy](https://github.com/copiousfreetime/launchy) and may not work in all environments). There are two ways the command can be run in. First, if you want to open the current story directly.

```plain
$ pivotal open
```

Second, if you want to open the entire project

```plain
$ pivotal open project
```
