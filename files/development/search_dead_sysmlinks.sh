#!/bin/sh

# Q: What does this script do?
# A: It shows all files which have link to another non-existing file (so called 'dead links')

find / -type l -exec /bin/sh -c "[ -e '{}' ] ||  echo 'Found dead link {}'" \;  


# - Searches from the root (/)
# - Searches for symlinks (-type l)
# - When it finds a symlink, it checks if the symlink does exist. If not, display a message
