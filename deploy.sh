#! /bin/bash
CURRENT_DIR=`pwd`
#ESCRIPT DEFICIENTE!!!!
mkdir /tmp/blog_source
cd /tmp/blog_source
jekyll build --destination /tmp/blog_site
cd $CURRENT_DIR
git checkout master
rm -rf *
cp -r /tmp/blog_site .
cd blog_site
cp -r . ../
rm -rf blog_site

