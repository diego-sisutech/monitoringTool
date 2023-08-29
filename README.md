# Sisu Tech Telepresence Automation

This script automates the process of selecting services to work on, restarting telepresence when changes are made, and continuously monitoring specified directories for changes.

## Script Overview

The script performs the following steps:

1. Cleans up telepresence by running `telepresence quit`.
2. Lists all services in the `$base_path/backend/` directory and prompts the user to select one or more services to work on.
3. Starts telepresence for the selected services.
4. Monitors the `$base_path/$packages_path` directory for changes to files with specified extensions (`mts`, `json`, `ts`).
5. When a change is detected, it runs `pnpm run build` in the package directory, restarts telepresence, and then continues monitoring for changes.

## Usage

Run the script by running:

```sh
bash start.sh
```

## npm start

The `npm start` command, as specified in your `package.json`, uses `nodemon` to monitor the `src/` directory for changes to `.sh` files and then executes `bash src/start.sh` whenever a change is detected.

## Notes

- The script modifies the `src/app.mts` file for each selected service by adding and then removing a `console.log();` line. This is done to trigger a restart of telepresence.
- The script uses `fswatch` to monitor the specified directories for changes. It may not work on all operating systems or file systems. Please refer to the [fswatch documentation](https://emcrisostomo.github.io/fswatch/) for more information.
