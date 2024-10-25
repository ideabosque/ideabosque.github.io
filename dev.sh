#!/bin/sh
folder="./vendor/bundle"

if [ -d "$folder" ]; then
    echo "存在依赖"
else
   bundle config set --local path vendor/bundle
   bundle install 
   bundle update
fi

bundle exec jekyll serve