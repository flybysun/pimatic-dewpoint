# Pimatic-Dewpoint

Dew point calculation support for <a href="http://pimatic.org/">Pimatic</a>. 
This plugin calculates the dew point temperature from the given temperature and humidity 
variables in Pimatic. 

## Theoretical Background

The dew point temperature DT is defined as a dimesion at which the actual degree of saturation of water in the air is at 100% RH (relative humidity). If a body at this temperature or below is exposed to this air condition, water on its surface will condense.
The dew point can be calculated approximately with the values of the relative humidity and the temperature of the air. 

The basis for the computation is the the approximation formula of the saturation vapor pressure:

P<sub>vs</sub>(T) = 6.1078 * 10<sup><sup>(a * T)</sup>/<sub>(b + T)</sub></sup>

where a = 7.5, b = 237.3 for temperatures >= 0°C
  and a = 7.6, b = 240.7 for temperatures < 0°C

The relationship of vapor pressure and saturation vapor pressure is represented as:

P<sub>v</sub>(rh, T) = P<sub>vs</sub>(T) * <sup>rh</sup>/<sub>100</sub>

Putting P<sub>v</sub>(rh, T) instead of P<sub>vs</sub>(T) into the first formula and dissolving it to T leads to the dew point:

DT = <sup>(b * v)</sup>/<sub>(a - v)</sub>

where v is:

log<sub>10</sub>(<sup>P<sub>v</sub>(rh, T)</sup>/<sub>6.1078</sub>)


## Usage

A good way to get these values is the usage of a combined temperature and humidity sensor (eg. DHT22).



## Configuration

Example:

    {
        "id": "dew",
        "class": "DewPointDevice",
        "name": "Dew Point",
        "temperatureRef": "$homeduino-airclimate.temperature",
        "humidityRef": "$homeduino-airclimate.humidity"
    }
