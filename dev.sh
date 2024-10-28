#!/bin/sh
folder="./vendor/bundle"

if [ -d "$folder" ]; then
    echo "依赖已安装，直接运行..."
else
   bundle config set --local path vendor/bundle
   bundle install --verbose
   bundle update
fi

bundle exec jekyll serve