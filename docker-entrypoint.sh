#!/bin/bash
mongod --smallfiles -v --logpath /tmp/mongo --fork --bind_ip 127.0.0.1
