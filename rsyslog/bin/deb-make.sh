#!/bin/sh

cd /tmp || exit 1

if [ ! -d collab-maint-rsyslog ]; then

	# source repository cloned from collab git://anonscm.debian.org/collab-maint/rsyslog.git
	# ?? set for fetch from origin 'git config remote.origin.fetch 'refs/heads/*:refs/heads/*'' to be able to fetch from upstream 'git fetch --all'
	# after each fetch 'git update-server-info' run
	# enable hooks/post-update for https
	git clone http://esb.metacentrum.cz/collab-maint-rsyslog.git

	cd collab-maint-rsyslog
	git remote set-url origin --push bodik@esb.metacentrum.cz:/data/collab-maint-rsyslog.git
else
	cd collab-maint-rsyslog
	git pull
fi

if [ -z "$RBVERSION" ]; then
	#by default we build latest revision found in collab sources
	RBVERSION=$(git branch -a | grep "\.rb[0-9]\+" | sed 's#remotes/origin/##' | sort -rV | head -1 | sed 's/*//g' | sed 's/ //g')
	
fi
git checkout $RBVERSION
service rsyslog stop
gbp buildpackage --git-export-dir=../build-area/ -us -uc --git-debian-branch=$RBVERSION

