Bunch of scripts I use for my implementation of Hubot (called Jarvis).
<ul>
<li><b>jarvis</b> - hubot init script using forever (https://github.com/nodejitsu/forever) to make sure the process restarts if it dies</li>
<li><b>openhab.coffee</b> - plugin for getting values from a local OpenHAB installation (http://openhab.org). Uses node-soupselect (https://github.com/harryf/node-soupselect) and node-htmlparser (https://github.com/tautologistics/node-htmlparser/). Has support for "translating" OpenHAB lookup values to something more meaningful, telling hubot the phrase "when I say x I mean y", where y is the actual lookup value in OpenHAB, will allow you to use either x OR y for asking "what is..."<br><br>
For example: <br><code>@hubot when I say the greenhouse temperature I mean GreenhouseTemperature</code><br>will make <br><code>@hubot what is GreenhouseTemperature</code><br>or<br><code>@hubot what is the greenhouse temperature</code><br>valid<br><br>Now supports setting of values<br><code>@hubot set value of Light to ON</code><br>can be combined with "when I say x I mean y" eg.<br><code>@hubot when I say on I mean ON</code><br>to handle case sensitivity
</li>
<li><b>rick.coffee</b> - Some general debugging stuff
</ul>
