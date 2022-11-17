#!/bin/bash

rsync -avc -e "ssh -i ~/.ssh/id_rsa_interpreter" --delete /Users/woodhamc/Documents/soteria-other/JCoz ubuntu@192.168.64.12:/home/ubuntu