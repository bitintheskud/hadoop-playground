# Introduction

/!\ This script is still in DEVELOPMENT. do not use /!\

Try it Yourself: Installing Hadoop Using the Apache Release

The script will install a pseudo-distributed mode Hadoop cluster using the latest Hadoop release downloaded from hadoop.apache.org.

# Prerequisites

This script has been tested in the following environment : 

  - Cloud provider : OVH
  - CentOS 7.4.1708 
  - 8 CPU cores
  - 32GB RAM
  - 240GO DISK
  - A gateway to the internet
  
This is a big config for a lab environnement and you should be able to run the pseudo cluster on a smaller node.

# What we'll do

  - Install necessary pkg
  - Download, uncompress hadoop
  - Configure hadoop, hdfs, yarn, a user..
  - Run some test to see if everything work. 

# How to use the scripts

Run as root.

```
$ git clone https://github.com/bitintheskud/hadoop-playground.git
$ cd  hadoop-playground && bash ./setup.sh
```

# What to improve 

The script is basically a list of sequential command. 
There's a lot to improve and I don't have much time to spend on it.

  [ ] add source / conf file 
  [ ] re-engineer with lib, functions. 
  [ ] Support other distrib (debian)

