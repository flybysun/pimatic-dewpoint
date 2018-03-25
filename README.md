# Pimatic-Dewpoint

Dew point, absolute humidity, wind chill factor, heat index, and apparent temperature calculation support 
for <a href="http://pimatic.org/">Pimatic</a>. 

This plugin calculates the dew point temperature, absolute humidity, and the heat index temperature
from the given temperature and relative humidity variables in Pimatic. Additionally, it can also calculate the
wind chill factor and the apparent temperature if a variable reference for wind speed is provided. For all values
metric, imperial, and ISO measures are supported.

## Theoretical Background

### Dew Point

The dew point temperature <i>DT</i> is defined as a dimension at which the actual degree of saturation of water in the 
air is at 100% RH (relative humidity). If a body at this temperature or below is exposed to this air condition, water 
on its surface will condense. 
The dew point can be calculated approximately with the values of the relative humidity and the temperature of the air. 

The basis for the computation is the the approximation formula of the saturation vapor pressure:

<i>P<sub>vs</sub>(T) = 6.1078 * 10<sup><sup>(a * T)</sup>/<sub>(b + T)</sub></sup></i>

where a = 7.5, b = 237.3 for temperatures T >= 0°C<br>
  and a = 7.6, b = 240.7 for temperatures T < 0°C

The relationship of the actual vapor pressure and saturation vapor pressure is represented as:

<i>P<sub>v</sub>(rh, T) = P<sub>vs</sub>(T) * <sup>rh</sup>/<sub>100</sub></i>

Putting <i>P<sub>v</sub>(rh, T)</i> instead of <i>P<sub>vs</sub>(T)</i> into the first formula and dissolving it 
to <i>T</i> leads to the dew point <i>DT</i>:

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

### Wind Chill

For temperatures below 10 degrees Celsius the wind chill is the lowering of the body temperature due to 
the passing-flow of lower-temperature air (wind). The calculation is performed according to the Canada Windchill Index
established in 2001. The formula for metric values is as follows:

<i>T<sub>wc</sub> = 13.12 + 0.6215T<sub>a</sub> + (0.3965v<sub>a</sub> - 11.37)v<sup>+0.16</sup></i>

where <i>T<sub>wc</sub></i> is the wind chill temperature,
 and <i>T<sub>a</sub></i> is the air temperature, 
 and <i>v</i> is the wind speed in km per hour.

### Heat Index

For temperatures starting from 27 degrees Celsius, heat index combines temperature and relative humidity as an attempt 
to determine the human-perceived equivalent temperature. The calculation is based on the work of Robert G. Steadman, 
published in the Journal of Applied Meteorology in 1979. The formula uses several constants c<sub>1</sub> through
 c<sub>9</sub> as follows:
 
<i>T<sub>hi</sub> = c<sub>1</sub> + c<sub>2</sub> Ta + c<sub>3</sub> R + c<sub>4</sub> Ta R + c<sub>5</sub> Ta<sup>2</sup> + c<sub>6</sub> R<sup>2</sup> + c<sub>7</sub> Ta<sup>2</sup>R + c<sub>8</sub> Ta R<sup>2</sup> + c<sub>9</sub> Ta<sup>2</sup> R<sup>2</sup></i>

where <i>T<sub>hi</sub></i> is the heat index,
  and <i>T<sub>a</sub></i> is the air temperature, 
  and <i>R</i> is the relative humidity. 
  
| constant      | value for Celsius |
|:--------------|:------------------|
| c<sub>1</sub> | −8.784695         |
| c<sub>2</sub> | 1.61139411        |
| c<sub>3</sub> | 2.338549          |
| c<sub>4</sub> | −0.14611605       |
| c<sub>5</sub> | −1.2308094 · 10<sup>−2</sup> |
| c<sub>6</sub> | −1.6424828 · 10<sup>−2</sup> |
| c<sub>7</sub> | 2.211732 · 10<sup>−3</sup> |
| c<sub>8</sub> | 7.2546 · 10<sup>−4</sup> |
| c<sub>9</sub> | −3.582 · 10<sup>−6</sup> |

### Apparent Temperature

Apparent temperature is the temperature equivalent perceived by humans, caused by the combined effects of 
 air temperature, relative humidity and wind speed. It is determined as follows:
 * wind chill temperature for air temperature below 10 degrees Celsius
 * heat index temperature for air temperatures starting from 27 degrees Celsius and relative humidity staring from 40%
 * air temperature, otherwise
 
 Note, the wet bulb globe temperature is not used.

### Sources 

- [Wikipedia Dew Point](https://en.wikipedia.org/wiki/Dew_point)
- [Wikipedia Wind Chill](https://en.wikipedia.org/wiki/Wind_chill)
- [Wikipedia Heat Index](https://en.wikipedia.org/wiki/Heat_index)
- [Wikipedia-Deutsch Hitzeindex](https://de.wikipedia.org/wiki/Hitzeindex)
- [Wikipedia Apparent Temperature](https://en.wikipedia.org/wiki/Apparent_temperature)
- [FAQs.org Temp, Humidity & Dew Point](http://www.faqs.org/faqs/meteorology/temp-dewpoint)
- [Wikipedia Humidity](https://en.wikipedia.org/wiki/Humidity)
- [Vaisala Calculation formulas for humidity](http://www.vaisala.com/Vaisala%20Documents/Application%20notes/Humidity_Conversion_Formulas_B210973EN-F.pdf)
- [Wetterochs](http://www.wetterochs.de/wetter/feuchte.html)


## Usage

The intention to calculate the dew point is to see if cold spots (for instance cold floors and walls in the closet) tend 
to become wet because their temperature is below the dew point of the surrounding air temperature. This also happens 
often in old houses with weak isolation when it is cold outside, but the air is heated and the walls are poorly 
isolated to the outside.

A good way to get these values is the usage of a combined temperature and humidity sensor (eg. DHT22) to measure the 
air climate and to calculate the dew point.

An additional sensor (eg. DS18B20) has directly contact to the cold spots and its temperature can be compared to the 
dew point temperature.



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
