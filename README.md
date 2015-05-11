# dev-pimatic-dewpoint

Dew Point Plugin for Pimatic. This plugin calculates the dew point temperature from the given temperature and humidity 
variables in Pimatic.

## Configuration

Example:

    {
          "id": "dew1",
          "class": "DewPointDevice",
          "name": "Dew Point Temperature",
          "temperatureRef": "$mySensor1.temperature",
          "humidityRef": "$mySensor1.humidity"
    }
