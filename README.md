# Catapult
Catapult will allow you to run 1 quick `p run <project>` command that will do the following:
- Stop your current project in whichever way it should stop (ie: docker-compose down, stopping npm, etc...)
- Switch to your new project, and initialize that with everything it needs, then put you in a tmux session with different windows for code and background processes

## Installation

1. Clone the repository to your local machine:
    ```sh
    git clone https://github.com/andyabih/catapult.git
    ```

2. Move into the catapult directory:
    ```sh
    cd catapult
    ```

3. Move the executable to `/usr/local/bin/` (or any other directory in your PATH):
    ```sh
    mv ~/catapult/p /usr/local/bin/
    ```
    
4. Modify the `p` file and change the paths of the Python parser, your projects directory, and whatever code editor you use
   ```sh
    # Development directory that holds all the project folders
    DEV_DIR="$HOME/dev"
    
    # A python script that parses the .catapult.yml file and returns the command to run
    PARSE_YAML_SCRIPT="$HOME/parse_yaml.py"
    
    # Name of the code editor to use
    CODE_EDITOR="nvim"
    ```

## Configuration

Catapult relies on a configuration file, `.catapult.yml`, in each of your project directories. The configuration file specifies the commands that should be run to start and stop the project, as well as any background tasks that should be run in separate tmux panes.

Here is an example of a `.catapult.yml` file:

```yaml
run: docker-compose up
down: docker-compose down
bg:
  - sail artisan queue:work
  - npm run watch
```

In this example, the run command starts the project with `docker-compose up -d`. The down command stops the project with `docker-compose down`. Two background tasks are also specified: `sail artisan queue:work` and `npm run watch`, each of which will be run in a separate tmux pane.

## Commands
- `p run <projectname>`: This command will stop any currently running project(s), then start the new project specified by `<projectname>`.
- `p run -p <projectname>`: This command will start the new project specified by `<projectname>` in parallel with any currently running project(s).
- `p stop`: This command will stop all currently running project(s).
- For `p run`, if multiple project names are provided, each will be run in a separate tmux session.

The project name should match the folder name of your project.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.
