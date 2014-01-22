#! /bin/bash
CURRENT_DIR=`pwd`

mkdir /tmp/blog_source
cp /tmp/blog_source
jekyll build --destination /tmp/blog_site
cd $CURRENT_DIR
git checkout master
rm -rf .
cp -r /tmp/blog_site .
cd blog_site
cp -r . ../
rm -rf blog_site

