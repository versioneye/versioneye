#!/bin/bash

git push origin develop
git push bitbucket develop
git checkout master
git merge develop
git push origin master
git push bitbucket master
git checkout develop
