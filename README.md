# Pimatic-Dewpoint

Dew point and absolute humidity calculation support for <a href="http://pimatic.org/">Pimatic</a>. 
This plugin calculates the dew point temperature and absolute humidity from the given temperature and relative humidity 
variables in Pimatic. 

## Theoretical Background

### Dew Point

The dew point temperature <i>DT</i> is defined as a dimesion at which the actual degree of saturation of water in the air is at 100% RH (relative humidity). If a body at this temperature or below is exposed to this air condition, water on its surface will condense.
The dew point can be calculated approximately with the values of the relative humidity and the temperature of the air. 

The basis for the computation is the the approximation formula of the saturation vapor pressure:

<i>P<sub>vs</sub>(T) = 6.1078 * 10<sup><sup>(a * T)</sup>/<sub>(b + T)</sub></sup></i>

where a = 7.5, b = 237.3 for temperatures T >= 0°C<br>
  and a = 7.6, b = 240.7 for temperatures T < 0°C

The relationship of the actual vapor pressure and saturation vapor pressure is represented as:

<i>P<sub>v</sub>(rh, T) = P<sub>vs</sub>(T) * <sup>rh</sup>/<sub>100</sub></i>

Putting <i>P<sub>v</sub>(rh, T)</i> instead of <i>P<sub>vs</sub>(T)</i> into the first formula and dissolving it to <i>T</i> leads to the dew point <i>DT</i>:

<i>DT = <sup>(b * v)</sup>/<sub>(a - v)</sub></i>

where <i>v</i> is:

<i>log<sub>10</sub>(<sup>P<sub>v</sub>(rh, T)</sup>/<sub>6.1078</sub>)</i>

### Absolute Humidity

Absolute humidity is the total mass of water vapor present in a given volume of air. Assuming ideal gas
 behaviour it can be calculated as follows:
 
<i>A = c · P<sub>v</sub> / T</i>

where c = 2.16679 gK/J
  and P<sub>v</sub> denotes the vapour pressure in Pa
  and T denotes the temperature in K
  
### Sources 
- [Wikipedia Dew Point](https://en.wikipedia.org/wiki/Dew_point)
- [FAQs.org Temp, Humidity & Dew Point](http://www.faqs.org/faqs/meteorology/temp-dewpoint)
- [Wikipedia Humidity](https://en.wikipedia.org/wiki/Humidity)
- [Vaisala Calculation formulas for humidity](http://www.vaisala.com/Vaisala%20Documents/Application%20notes/Humidity_Conversion_Formulas_B210973EN-F.pdf)


## Usage

The intention to calculate the dewpoint is to see if cold spots (for instance cold floors and walls in the closet) tend to become wet because their temperature is below the dew point of the surrounding air temperature. This also happens often in old houses with weak isolations when it is cold outside, but the air is heated and the walls are poorly isolated to the outside.

A good way to get these values is the usage of a combined temperature and humidity sensor (eg. DHT22) to measure the air climate and to calculate the dew point.

An additional sensor (eg. DS18B20) has directly contact to the cold spots and its temperature can be compared to the dew point temperature.



## Configuration

Example:

    {
        "id": "dew",
        "class": "DewPointDevice",
        "name": "Dew Point",
        "temperatureRef": "$homeduino-airclimate.temperature",
        "humidityRef": "$homeduino-airclimate.humidity"
    }

By default, the referenced temperature is expected to be in °C. To switch to imperial units, set the "units"
property to "imperial" as shown in the following example:

    {
        "id": "dew",
        "class": "DewPointDevice",
        "name": "Dew Point",
        "temperatureRef": "$homeduino-airclimate.temperature",
        "humidityRef": "$homeduino-airclimate.humidity",
        "units": "imperial"
    }

## Acknowledgements    
Thank you <a href="https://github.com/mwittig">Marcus Wittig</a> and <a href="https://github.com/Icesory">Icesory</a> 
 for helping me in this project and as well  <a href="https://github.com/sweetpi">sweet pi</a> for his work on the 
 software <a href="http://pimatic.org/">Pimatic</a>!
