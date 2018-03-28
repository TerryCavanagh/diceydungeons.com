@echo off

cd source

jekyll build

cd ..

y | del "docs" /s
y | robocopy source docs /S /E