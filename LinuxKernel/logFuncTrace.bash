#!/bin/bash


## Exit the script if any step encounters error
set -e

# Print Help message
function printHelp() {
  echo -e ""
  echo -e "\t$0 requires input: "
  echo -e "\t\t0 to print ftrace"
  echo -e "\t\t1 <module-name> to enable collection of ftrace"
  echo -e "\tRun script as follows: "
  echo -e "\t\t$0 0"
  echo -e "\t\t\tOR"
  echo -e "\t\t$0 1"
  echo -e ""
  exit
}

# Check if user wants to enable or print Ftrace log
if [ "$#" -eq 0 ]; then
  printHelp
fi

# Determine request to print is valid
if [ "$1" -eq 0 ]; then
  if [ "$#" -gt 1 ]; then
    printHelp
  fi
fi

# Determine request to enable ftrace is valid
if [ "$1" -eq 1 ]; then
  if [ "$#" -ne 2 ]; then
    printHelp
  fi
fi

#
#  Background: A "tracer" determines what kinds of logs can be
#  collected. The log is dumped into a ring buffer referenced by
#  file handle called "trace".

#  One can see what tracers are available by reading the text
#  file: cat /sys/kernel/debug/tracing/available_tracers
#
#  One must choose a tracer and apply it to current_tracer file 
#   echo function > current_tracer
#
#


# Capture users Ftrace preference
logFlag=$1
moduleName=$2
traceDir='/sys/kernel/debug/tracing/'

# Variables used to capture data
timestamp=`printf '%(%Y-%m-%d-%M)T\n'`
ftraceDataDump="/tmp/ftraceDataDump_${timestamp}.txt"
ftraceFuncList="/tmp/ftraceFuncList_${timestamp}.txt"

# Cd into right wokring directory
cd  $traceDir

if [[ "$logFlag" -eq 1 ]]; then
  
  echo "Enabling function mode of ftrace for module ${moduleName}"

  #
  # The basic sequence is as follows:
  #   stop recording trace
  #   Reset / Disable current_tracer
  #   Select and apply a tracer
  #   Determine which functions should be traced
  #
  
  # Stop recording in trace buffer
  echo 0 > tracing_on
  
  # Disable current_tracer
  echo nop > current_tracer
  
  # Using "function" is not very helpful. It dumps a lot
  # of information that may not be very helpful. It could
  # be used if tracing for a few functions
  #
  echo function > current_tracer
  
  # Determine which functions should be traced
  # Choosing a module scope will dump a lot of
  # information, so try to limit to functions
  # with certain substrings
  #
  # echo ":mod:amdgpu" >  set_ftrace_filter
  # echo 'kfd_*' >  set_ftrace_filter
  # echo 'amdgpu_*' >  set_ftrace_filter
  echo ':mod:'${moduleName} >  set_ftrace_filter

  cat  set_ftrace_filter > ${ftraceFuncList}
  numFuncs=`cat  set_ftrace_filter | wc -l`
  echo "Number of functions being traced is: ${numFuncs}"
  echo "File ${ftraceFuncList} has the list of functions being traced"

  # Start recording in trace buffer
  echo 1 > tracing_on

else

  echo " "
  echo "Print function trace buffer into ${ftraceDataDump}"

  #
  # The basic sequence is as follows:
  #   stop recording trace
  #   Reset the function filter
  #   Copy or cat the trace ring buffer
  #     This must be done before reset
  #   Reset the current_tracer
  #

  # Stop recording in trace buffer
  echo 0 > tracing_on
  
  # Reset the function filter
  echo >  set_ftrace_filter

  # Echo trace data into log file
  cat trace > ${ftraceDataDump}
  echo " "
  
  # Reset the trace ringer buffer
  echo nop > current_tracer

fi


