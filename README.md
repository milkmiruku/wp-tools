# WordPress tools
========

A fork of [linepress WP-Tools](https://github.com/linepress/wp-tools).

The main difference is that I minimize extra config folders and files. And add options local and production options. The project is very customizable.

# Requirements and Assumptions
This script assumes you're using OSX and WP-CLI. WP-CLI itself doesn't work well with MAMP out of the box, so if you're using homebrew or a self compiled set-up of PHP/MYSQL you'll probably be fine.

# Usage
Execute in terminal
`setup.sh` and follow the instructions.

#Example
1. Run the script from a folder where you'd like your dev site to live.
2. Name the project. Slug is used throughout the build in your theme, function prefixes, etc. 
3. Optionally connect it to a private BB repo.

![alt text](https://raw.github.com/drrobotnik/wp-tools/master/create-repo.png "Name the project, slug is used throughout the build in your theme, function prefixes, etc. Optionally connect it to a private BB repo.")


1. Automatically builds local DB based on given inputs.
2. Installs latest version of WP via [WP-CLI](http://wp-cli.org).
3. Creates a local-config file and modifies wp-config credentials if given for "live credentials".

![alt text](https://raw.github.com/drrobotnik/wp-tools/master/create-config.png "Installs latest version of WP via WP-CLI.")


1. Installs developer plugins. ACF, Developer, WP_Debug, etc. If you fork this project you can easily change the ones I've chosen.
2. Optionally (recommended) installs and activates a custom [_s](http://underscores.me) theme. This theme generates Title, description, and prefixes all functions. Saving tons of initial work.

![alt text](https://raw.github.com/drrobotnik/wp-tools/master/install-underscores.png "Installs developer plugins.")


# Credit
- [linepress/WP-Tools](https://github.com/linepress/wp-tools)
- [Mark on WordPress - WP local dev tips](http://markjaquith.wordpress.com/2011/06/24/wordpress-local-dev-tips/)
- [WP-CLI](http://wp-cli.org)
- [_s](http://underscores.me)