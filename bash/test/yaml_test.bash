#!/bin/bash 
python -V
>files.ok
for yaml_file in `/usr/bin/find ${1:-.} -name "*.yml" -type f`
do
  yamllint $yaml_file
  if [ $? -ne 0 ]
  then 
    echo $yaml_file
    RETURN_CODE=1
  else
    echo -n "." >> files.ok
  fi
done
cat ./files.ok
wc -c files.ok
exit ${RETURN_CODE:-0}
