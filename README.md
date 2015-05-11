# dev-pimatic-dewpoint

Dew Point Plugin for Pimatic. This plugin calculates the dew point temperature from the given temperature and humidity 
variables in Pimatic.

## Configuration

Example:

    {
        "id": "dew",
        "class": "DewPointDevice",
        "name": "Dew Point",
        "temperatureRef": "$homeduino-airclimate.temperature",
        "humidityRef": "$homeduino-airclimate.humidity"
    }
