# Slurry
A tool for controlling the flow of data to graphite.

## Usage

### Getting data into slurry

    while true; do
      /path/to/my/script | /path/to/bin/slurry;
      sleep 60;
    done


### Getting data out of slurry and into graphite

    ./bin/liaise

### Inspecting the state

    ./bin/report

