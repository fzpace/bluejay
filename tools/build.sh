#!/bin/bash
source_path=$(dirname $(pwd))

usage() {
  echo "Usage: $0 [-l <A-W>] [-m <X|H|L>] [-d <integer>]" 1>&2
  exit 1
}

while getopts ":l:m:d:" o; do
  case "${o}" in
    l)
      layout=${OPTARG}
      ;;
    m)
      mcu=${OPTARG}
      ((mcu == "X" || mcu == "H" || mcu == "L")) || usage
      ;;
    d)
      deadtime=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${layout}" ] && [ -z "${mcu}" ] && [ -z "${deadtime}" ]; then
  # All optional parameters are missing
  target="all"
  params="all"
else
  if [ -z "${layout}" ] || [ -z "${mcu}" ] || [ -z "${deadtime}" ]; then
    # If one optional parameter is given, all are needed
    usage
  fi

  target="${layout}_${mcu}_${deadtime}"
  params="LAYOUT=${layout} MCU=${mcu} DEADTIME=${deadtime}"
fi

echo "Building ${target}"

docker run -t -d --name bluejay-$target --mount type=bind,source="$source_path",target=/root/source bluejay-build:latest
docker exec bluejay-$target sh -c "cd /root/source && make $params"
docker stop bluejay-$target > /dev/null
docker rm bluejay-$target > /dev/null
