#!/bin/bash
#
# This script has been adapted from the drush wrapper script + WP base install scratch
# and credits should go to the authors of those projects:
# http://drupal.org/project/drush
# https://gist.github.com/3157720

# Get the absolute path of this executable
ORIGDIR=$(pwd)
SELF_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && SELF_PATH=$SELF_PATH/$(basename -- "$0")
WP_TOOLS_PATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)


# Resolve symlinks - this is the equivalent of "readlink -f", but also works with non-standard OS X readlink.
while [ -h "$SELF_PATH" ]; do
	# 1) cd to directory of the symlink
	# 2) cd to the directory of where the symlink points
	# 3) Get the pwd
	# 4) Append the basename
	DIR=$(dirname -- "$SELF_PATH")
	SYM=$(readlink $SELF_PATH)
	SELF_PATH=$(cd $DIR && cd $(dirname -- "$SYM") && pwd)/$(basename -- "$SYM")
done
cd "$ORIGDIR"
echo "Working in $ORIGDIR"

# http://sterlinghamilton.com/2010/12/23/unix-shell-adding-color-to-your-bash-script/
# Example usage:
# echo -e ${RedF}This text will be red!${Reset}

Colors() {
	Escape="\033";
	BlackF="${Escape}[30m";   RedF="${Escape}[31m";   GreenF="${Escape}[32m"; YellowF="${Escape}[33m";  BlueF="${Escape}[34m";  Purplef="${Escape}[35m"; CyanF="${Escape}[36m";  WhiteF="${Escape}[37m"; 
	Reset="${Escape}[0m";
}
Colors;

# PROJECT init
echo -e ${YellowF}"Project slug (lowercase, no spaces):"${Reset}
read -e PROJECT
CLEAN_PROJECT=${PROJECT//[^a-zA-Z0-9]/}

# Create Project REPO

echo -e ${YellowF}"Create Project Repo? Bitbucket (y/n):"${Reset}
read -e SETUP_REPO

if [ "$SETUP_REPO" == "y" ] ; then
	echo "Owner (Leave blank if not team): "
	read -e BB_Owner
	echo "Username: "
	read -e BB_USER
	echo "Password: "
	read -s BB_PASS

echo "-u$BB_USER:$BB_PASS -X POST -d 'name=$PROJECT' -d 'owner=$BB_Owner' -d 'is_private=1' -d 'scm=git' https://api.bitbucket.org/1.0/repositories/"

	curl -u$BB_USER:$BB_PASS -X POST -d "name=$PROJECT" -d "owner=$BB_Owner" -d 'is_private=1' -d 'scm=git' https://api.bitbucket.org/1.0/repositories/

	git clone https://$BB_USER:$BB_PASS@bitbucket.org/$BB_Owner/$PROJECT.git

	HTTPDOCS="$ORIGDIR/$PROJECT"
	CNF="$ORIGDIR/$PROJECT"
	GIT_PATH="$HTTPDOCS/.git/hooks"
fi

if [ "$SETUP_REPO" != "y" ] ; then
	mkdir $PROJECT
	HTTPDOCS="$ORIGDIR/$PROJECT"
fi

cd $HTTPDOCS



# CNF
# TODO: Recreate cases where we don't create the repo
#echo "Creating cnf directory..."


#if [ -d $CNF ] ; then
#	echo "Removing existing cnf directory...";
#	rm -rf $CNF;
#fi
#mkdir "$CNF"
#echo -e ${GreenF}"cnf dir created"${Reset}

# MySQL DB
echo -e ${YellowF}"Creating LOCAL MySQL DB"${Reset}

echo "Database Name: [$CLEAN_PROJECT]"
	read -e LOCAL_DB_NAME
	if [ -z "$LOCAL_DB_NAME"] ; then
		LOCAL_DB_NAME=$CLEAN_PROJECT
	fi
echo "WP Database User: "
read -e LOCAL_DB_USER
echo "WP Database Password: "
read -s LOCAL_DB_PASS
echo "Database Access Password: "
read -s ACCESS_DB_PASS

Q1="CREATE DATABASE IF NOT EXISTS $LOCAL_DB_NAME;"
Q2="GRANT ALL ON '$LOCAL_DB_NAME'.* TO '$LOCAL_DB_USER'@'localhost' IDENTIFIED BY '$LOCAL_DB_PASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

echo -e ${YellowF}"Running SQL statement"${Reset}

MYSQL=`which mysql`
$MYSQL -uroot -p$ACCESS_DB_PASS -e "$SQL"

echo -e ${GreenF}"$LOCAL_DB_NAME DB created"${Reset}

if [ "$SETUP_REPO" == "y" ] ; then
	echo -e ${YellowF}"Adding git hooks for DB VCS"${Reset}
	cp $WP_TOOLS_PATH'/skeleton/pre-commit' $GIT_PATH'/pre-commit'
	sed -i.bak 's/dbuser/'$LOCAL_DB_USER'/g' $GIT_PATH/pre-commit
	sed -i.bak 's/dbpassword/'$LOCAL_DB_PASS'/g' $GIT_PATH/pre-commit
	sed -i.bak 's/dbname/'$LOCAL_DB_NAME'/g' $GIT_PATH/pre-commit
	sed -i.bak 's|projectpath|'$HTTPDOCS'|g' $GIT_PATH/pre-commit
	chmod +x $GIT_PATH/pre-commit

	cp $WP_TOOLS_PATH'/skeleton/post-merge' $GIT_PATH'/post-merge'
	sed -i.bak 's/dbuser/'$LOCAL_DB_USER'/g' $GIT_PATH/post-merge
	sed -i.bak 's/dbpassword/'$LOCAL_DB_PASS'/g' $GIT_PATH/post-merge
	sed -i.bak 's/dbname/'$LOCAL_DB_NAME'/g' $GIT_PATH/post-merge
	sed -i.bak 's|projectpath|'$HTTPDOCS'|g' $GIT_PATH/post-merge
	chmod +x $GIT_PATH/post-merge
fi

## Get WordPress
echo -e ${YellowF}"Running wp core download in httpdocs..."${Reset}
cd "$HTTPDOCS"
wp core download
echo -e ${GreenF}"WordPress Core downloaded"${Reset}

echo -e ${YellowF}"Getting settings.php..."${Reset}
#wget -P "$CNF" https://gist.github.com/raw/4009181/4dfcbf074ccc4b5f0b1c8bea1c04de2789a9ae76/settings.php
cp $WP_TOOLS_PATH'/skeleton/local-config.php' $HTTPDOCS'/local-config.php'

echo -e ${YellowF}"Editing local-config.php..."${Reset}
cd $HTTPDOCS
sed -i.bak 's/putyourdbnamehere/'$LOCAL_DB_NAME'/g' $HTTPDOCS/local-config.php
sed -i.bak 's/usernamehere/'$LOCAL_DB_USER'/g' $HTTPDOCS/local-config.php
sed -i.bak 's/yourpasswordhere/'$LOCAL_DB_PASS'/g' $HTTPDOCS/local-config.php
echo -e ${GreenF}"settings edited"${Reset}

echo -e ${YellowF}"Editing wp-config.php..."${Reset}
cp $WP_TOOLS_PATH'/skeleton/wp-config.php' $HTTPDOCS'/wp-config.php'
cd $HTTPDOCS
rm wp-config-sample.php

echo -e ${YellowF}"Do you have the live DB credentials? (y/n):"${Reset}
read -e PRODUCTION_DB_SETUP

if [ "$PRODUCTION_DB_SETUP" == "y" ] ; then
	echo "Database Name: "
	read -e DB_NAME
	echo "Database User: "
	read -e DB_USER
	echo "Database Password: "
	read -s DB_PASS

	sed -i.bak 's/putyourdbnamehere/'$DB_NAME'/g' ./wp-config.php
	sed -i.bak 's/usernamehere/'$DB_USER'/g' ./wp-config.php
	sed -i.bak 's/yourpasswordhere/'$DB_PASS'/g' ./wp-config.php
fi

# cleanup, remove any file backup files created.
rm -r *.bak

#TODO: Autogenerate SALTS?
#SECRET_KEYS="wget https://api.wordpress.org/secret-key/1.1/salt"
#sed -i.bak 's/WPT_SECRET_KEYS/'$SECRET_KEYS'/g' ./wp-config.php
echo -e ${YellowF}"wp-config.php written"${Reset}



# Install site
echo -e ${YellowF}"Installing WordPress..."${Reset}

echo "URL [http://127.0.0.1/$PROJECT]: "
read -e SITEURL
	if [ -z "$SITEURL"] ; then
		SITEURL="http://127.0.0.1/$PROJECT"
	fi
echo "Title: "
read -e SITETITLE
echo "Admin Name: "
read -e SITEADMIN_NAME
echo "Admin Username: "
read -e SITEADMIN
echo "E-mail: "
read -e SITEMAIL
echo "Site Password: "
read -s SITEPASS

echo "Install site? (y/n)"
read -e SITERUN
if [ "$SITERUN" != "y" ] ; then
  exit
fi

wp core install --url=$SITEURL --title=$SITETITLE --admin_name=$SITEADMIN --admin_email=$SITEMAIL --admin_password=$SITEPASS

wp rewrite structure %category%/%postname%

## Install plugins

wp plugin install backwpup
wp plugin install developer
wp plugin install google-analytics-for-wordpress
wp plugin install advanced-custom-fields
#wp plugin install w3-total-cache
#wp plugin install all-in-one-seo-pack
wp plugin install rewrite-rules-inspector

wp plugin delete hello

wp plugin update-all

echo "Install _s theme? (y/n)"
read -e THEME_INSTALL

if [ "$THEME_INSTALL" != "y" ] ; then
  exit
fi

echo "Admin Website: "
read -e SITEADMIN_URI
echo "Theme Description: "
read -e THEME_DESCRIPTION

echo ${YellowF}"Installing _S Theme with project information..."

## Install theme
cd wp-content/themes
curl -d underscoresme_name="$SITETITLE" -d underscoresme_slug="$PROJECT" -d underscoresme_author="$SITEADMIN_NAME" -d underscoresme_author_uri="$SITEADMIN_URI" -d underscoresme_description="$THEME_DESCRIPTION" -d underscoresme_generate_submit="Generate" -d underscoresme_generate="1" http://underscores.me > underscores.zip
unzip underscores && rm underscores.zip
cd "$HTTPDOCS"

wp theme activate $PROJECT

### Sass support

#git clone git://github.com/sanchothefat/wp-sass.git wp-content/plugins/wp-sass
#cd wp-content/plugins/wp-sass && git submodule update --init --recursive && cd /var/www/$PROJECT

### Semantic.gs

#cd wp-content/themes/bones/library/scss
#wget https://raw.github.com/twigkit/semantic.gs/master/stylesheets/scss/grid.scss -O _grid.scss
#cd "$ORIGDIR/httpdocs"

# Server user and group
#chown www-data * -R
#chgrp www-data * -R
