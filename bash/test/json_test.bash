#!/bin/bash 
python -V
>files.ok
for json_file in `/usr/bin/find ${1:-.} -name "*.json" -type f`
do
  python -m json.tool $json_file >/dev/null
  if [ $? -ne 0 ]
  then 
    echo $json_file
    RETURN_CODE=1
  else
    echo -n "." >> files.ok
  fi
done
cat ./files.ok
wc -c files.ok
exit ${RETURN_CODE:-0}
