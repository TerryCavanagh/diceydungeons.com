@echo off

cd source

call jekyll build

cd ..

del "docs" /s /F /Q 
robocopy source/_site docs /S /E

cd docs

echo. 2>.nojekyll

cd ..

call git pull
call git add .
call git add -u
call git commit -a
call git push
