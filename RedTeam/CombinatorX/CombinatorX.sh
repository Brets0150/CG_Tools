#!/bin/bash
PR_SCRIPT_DIR="""$(dirname "$(realpath "$0")")"""
help_message=$("${PR_SCRIPT_DIR}/CombinatorX.bin" -h)

# Parse command line arguments using getopts
while getopts "ks:l:1:2:3:4:5:6:7:8:" opt; do
  case ${opt} in
    k )
      keyspace=1
      ;;
    s )
      skip=$OPTARG
      ;;
    l )
      limit=$OPTARG
      ;;
    1 )
      list1=$OPTARG
      ;;
    2 )
      list2=$OPTARG
      ;;
    3 )
      list3=$OPTARG
      ;;
    4 )
      list4=$OPTARG
      ;;
    5 )
      list5=$OPTARG
      ;;
    6 )
      list6=$OPTARG
      ;;
    7 )
      list7=$OPTARG
      ;;
    8 )
      list8=$OPTARG
      ;;
    * )
      echo "Invalid option: -$OPTARG requires an argument" 1>&2
      echo "$help_message" 1>&2
      exit 1
      ;;
  esac
done

# Check if the  agrument flag '--keyspace' is passed
if [ "$keyspace" == 1 ]; then
    if [ -n "$list1" ]; then
      list1_size=$(wc -l < "${list1}")
      if [ "$list1_size" == 0 ]; then
        list1_size=1
      fi
    else
      list1_size=1
    fi


    if [ -n "$list2" ]; then
      list2_size=$(wc -l < "${list2}")
      if [ "$list2_size" == 0 ]; then
        list2_size=1
      fi
    else
      list2_size=1
    fi


    if [ -n "$list3" ]; then
      list3_size=$(wc -l < "${list3}")
      if [ "$list3_size" == 0 ]; then
        list3_size=1
      fi
      else
        list3_size=1
    fi


    if [ -n "$list4" ]; then
      list4_size=$(wc -l < "${list4}")
      if [ "$list4_size" == 0 ]; then
        list4_size=1
      fi
    else
        list4_size=1
    fi


    if [ -n "$list5" ]; then
      list5_size=$(wc -l < "${list5}")
      if [ "$list5_size" == 0 ]; then
        list5_size=1
      fi
    else
        list5_size=1
    fi


    if [ -n "$list6" ]; then
      list6_size=$(wc -l < "${list6}")
      if [ "$list6_size" == 0 ]; then
        list6_size=1
      fi
      else
        list6_size=1
    fi


    if [ -n "$list7" ]; then
      list7_size=$(wc -l < "${list7}")
      if [ "$list7_size" == 0 ]; then
        list7_size=1
      fi
    else
        list7_size=1
    fi


    if [ -n "$list8" ]; then
      list8_size=$(wc -l < "${list8}")
      # If the listX_size is equal to 0, then the product is 1.
      if [ "$list8_size" == 0 ]; then
        list8_size=1
      fi
      else
        list8_size=1
    fi


    # For each listX_size that is not equal to 0, times each non-zero listX_size.
    # If listX_size is equal to 0, then the product is 1.
    keyspace=$(( list1_size * list2_size * list3_size * list4_size * list5_size * list6_size * list7_size * list8_size ))
    echo "$keyspace"
    exit 0
fi
cmd="${PR_SCRIPT_DIR}/CombinatorX.bin"
chmod 755 "${cmd}"
# If the skip flag is set, append the skip flag to the command.
if [ -n "$skip" ]; then
  cmd="${cmd} -s ${skip}"
fi
# If the limit flag is set, append the limit flag to the command.
if [ -n "$limit" ]; then
  cmd="${cmd} -l ${limit}"
fi
# For each listX that is set, append the listX to the command.
if [ -n "$list1" ]; then
  cmd="${cmd} -1 ${list1}"
fi
if [ -n "$list2" ]; then
  cmd="${cmd} -2 ${list2}"
fi
if [ -n "$list3" ]; then
  cmd="${cmd} -3 ${list3}"
fi
if [ -n "$list4" ]; then
  cmd="${cmd} -4 ${list4}"
fi
if [ -n "$list5" ]; then
  cmd="${cmd} -5 ${list5}"
fi
if [ -n "$list6" ]; then
  cmd="${cmd} -6 ${list6}"
fi
if [ -n "$list7" ]; then
  cmd="${cmd} -7 ${list7}"
fi
if [ -n "$list8" ]; then
  cmd="${cmd} -8 ${list8}"
fi
# Run the command
${cmd}
exit 0