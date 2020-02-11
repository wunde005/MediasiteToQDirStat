#~/bin/bash

args=("$@")
action=${args[0]}
if [[ "${args[0]}" == archive ]]
then
  echo archive
  ppath=${args[1]}
elif [[ "${args[0]}" == delete ]]
then
  echo delete
  ppath=${args[1]}
elif [[ "${args[0]}" == inspect ]]
then
  echo inspect
  ppath=${args[1]} 
else
  action=archive
  ppath=${args[0]}
fi

grep -F ",$ppath," $PWD/idmap.txt >> $PWD/$action.id
