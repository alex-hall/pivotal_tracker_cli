# PivotalTrackerCli

The purpose of this gem is to facilitate the day to day  **engineering** workflow with Pivotal Tracker.
  
This gem is not intended to be a 1:1 cli replacement for the tracker website/app.

Current features:
- Get all stories assigned to a given user
- Grep the 3 latest iterations from the backlog (including status and assigned to)
- Show basic details about any specific story
- Update the status of any available story/chore
- Colorized and markdown formatted story output

TODOs: 
- Make the current user configurable via command line
- Make the # of iterations configurable
- Make initial pt file configurable via command line
- Better error handling for initial setup & general error messages from Tracker API

## Installation

To pull in dependencies, simply run:

    $ bundle

## Setup

In order to use the gem you must first create a .pt file in the home directory: 

```bash
vim ~/.pt
```

Fill in the following details, and paste into the file: 

```yml

---
api_token: <API TOKEN HERE>
project_id: <PROJECT ID HERE>
usernames: [<USERNAME HERE>, ...]
```

Write, quit, and you're done!

NOTE: Details about getting an API token can be found in the [tracker API documentation](https://www.pivotaltracker.com/help/api/#Getting_Started): 

## Usage

The current commands for the gem are: 

```
Commands:
  pt backlog                     # Displays all stores for the 3 most recent iterations in the backlog
  pt help [COMMAND]              # Describe available commands or one specific command
  pt list                        # Lists all current stories for current user
  pt refresh                     # Refreshes the user cache from Tracker
  pt show [STORY_ID]             # Shows a specific story
  pt update [STORY_ID] [STATUS]  # Updates the status of a story, available statuses are: unstart, start, deliver, finish
  ```



## Development

To run the gem in development mode, simple cd to the project directory and run the following command: 

```bash
    bundle exec ./bin/pt
```

Once you're happy with the functionality you've built, simply bump the version in ```/lib/pivotal_tracker_cli/version.rb``` and run ```rake relase```.

This will output a gem to the ```pkg``` directory which you can then run ```gem install pkg/pivotal_tracker_cli-X.X.X.gem```.
Once you've installed the gem you can just use the ```pt``` namespace in your shell.  

NOTE: X.X.X in the example above is a place holder for the major, minor, and patch release versions. 


TODO: Push gem to Rubygems!!
 

## Contributing

In order to contribute, please create an issue to discuss the feature/bug/enhancement. If a pull request is in order, 
fork the repository, create a branch off of master, and make commits with very descriptive, passing commits. 

Please note that **_ALL_** code must be test driven to be accepted into the repository. No exceptions.


## Contributors

@alex-hall

@WRMilling

@lm185074


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

