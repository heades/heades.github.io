[Oh My Zsh] Would you like to check for updates?
Type Y to update oh-my-zsh: 


➜  _posts git:(gh-pages) ✗ 
➜  _posts git:(gh-pages) ✗ cd ..
➜  blog git:(gh-pages) ✗ cd _layouts/
➜  _layouts git:(gh-pages) ✗ ll
total 16
-rw-r--r--  1 heades  staff  2860 Dec  6 10:27 default.html
-rw-r--r--  1 heades  staff  2928 Dec  6 10:14 default.html~
➜  _layouts git:(gh-pages) ✗ cp default.html blog.html
➜  _layouts git:(gh-pages) ✗ 
➜  _layouts git:(gh-pages) 
➜  _layouts git:(gh-pages) cd ..
➜  blog git:(gh-pages) cd ..
➜  website  cd heades.github.io/
➜  heades.github.io git:(master) ✗ ll
total 104
-rw-r--r--   1 heades  staff   128 Dec  5 13:51 README.md
-rw-r--r--   1 heades  staff   131 Dec  6 20:09 _config.yml
-rw-r--r--   1 heades  staff   186 Dec  5 11:29 _config.yml~
drwxr-xr-x   3 heades  staff   102 Dec  6 19:47 _layouts
drwxr-xr-x  41 heades  staff  1394 Dec  6 07:32 _pubs
drwxr-xr-x   9 heades  staff   306 Dec  6 20:12 _site
drwxr-xr-x   4 heades  staff   136 Dec  6 20:12 _talks
drwxr-xr-x   3 heades  staff   102 Dec  5 10:41 images
drwxr-xr-x   4 heades  staff   136 Dec  5 11:05 includes
-rw-r--r--   1 heades  staff  1394 Dec  5 17:54 index.html
drwxr-xr-x   3 heades  staff   102 Dec  6 18:12 papers
-rw-r--r--   1 heades  staff  9810 Dec  6 07:44 pubs.html
-rw-r--r--   1 heades  staff  5568 Dec  5 11:20 pubs.html~
-rw-r--r--   1 heades  staff   511 Dec  6 20:01 talks.html
-rw-r--r--   1 heades  staff  9810 Dec  6 19:40 talks.html~
➜  heades.github.io git:(master) ✗ cd includes/
➜  includes git:(master) ✗ ll
total 176
-rw-r--r--   1 heades  staff  89080 Dec  5 11:04 cv.pdf
drwxr-xr-x  17 heades  staff    578 Dec  6 07:31 pubs
➜  includes git:(master) ✗ mkdir talks
➜  includes git:(master) ✗ cd talks/
➜  talks git:(master) ✗ ll
➜  talks git:(master) ✗ curl -o 2014-CLC.pdf http://metatheorem.org/wp-content/talks/CLC14.pdf
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1967k  100 1967k    0     0  1822k      0  0:00:01  0:00:01 --:--:-- 1823k
➜  talks git:(master) ✗ curl -o 2013-IMS.pdf http://metatheorem.org/wp-content/talks/UI-MiniSymp13.pdf
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1904k  100 1904k    0     0  1588k      0  0:00:01  0:00:01 --:--:-- 1588k
➜  talks git:(master) ✗ ll
total 7752
-rw-r--r--  1 heades  staff  1950558 Dec  6 20:17 2013-IMS.pdf
-rw-r--r--  1 heades  staff  2014592 Dec  6 20:13 2014-CLC.pdf
➜  talks git:(master) ✗ 